"use strict";

const { createHash } = require("node:crypto");
const { Firestore, FieldValue } = require("@google-cloud/firestore");
const { GoogleAuth } = require("google-auth-library");

const PROJECT_ID = "faithful-pantry";
const TIME_ZONE = "Europe/London";
const SOON_DAYS = 3;

const MAX_INSTALLATIONS = 100;
const MAX_PANTRY_ITEMS = 1000;
const MAX_SEND_ATTEMPTS = 1;

function calendarDate(now) {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(now);

  const get = (type) =>
    parts.find((part) => part.type === type).value;

  return `${get("year")}-${get("month")}-${get("day")}`;
}

function dateNumber(value) {
  if (typeof value !== "string") return null;

  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return null;

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);

  if (year < 2000 || year > 2100) return null;

  const date = new Date(Date.UTC(year, month - 1, day));

  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    return null;
  }

  return date.getTime() / 86400000;
}

function needsReminder(item, today) {
  if (
    item.status !== "active" ||
    !Number.isInteger(item.currentQuantity) ||
    item.currentQuantity <= 0
  ) {
    return false;
  }

  const expiry = dateNumber(item.expiryDate);
  const current = dateNumber(today);

  if (expiry === null || current === null) return false;

  const days = expiry - current;
  return days >= 0 && days <= SOON_DAYS;
}

function deliveryId(registrationPath, today) {
  return createHash("sha256")
    .update(`${registrationPath}|${today}`)
    .digest("hex");
}

function notificationMessage(token, today) {
  return {
    token,
    notification: {
      title: "Faithful Pantry reminder",
      body:
        "Some groceries are approaching their recorded expiry dates. " +
        "Open Faithful Pantry to review them."
    },
    webpush: {
      headers: {
        TTL: "3600",
        Urgency: "normal"
      },
      notification: {
        icon: "https://faithful-pantry.web.app/icons/Icon-192.png",
        tag: `pantry-expiry-${today}`
      },
      fcm_options: {
        link: "https://faithful-pantry.web.app/"
      }
    }
  };
}

async function reserveAttempt(db, registration, expectedToken, today) {
  const receipt = db
    .collection("_pushReminderDeliveries")
    .doc(deliveryId(registration.ref.path, today));

  return db.runTransaction(async (transaction) => {
    const current = await transaction.get(registration.ref);
    const previous = await transaction.get(receipt);
    const data = current.data();

    // Recheck opt-in and token after the initial scan.
    if (
      previous.exists ||
      !current.exists ||
      data.enabled !== true ||
      data.token !== expectedToken
    ) {
      return null;
    }

    transaction.create(receipt, {
      calendarDate: today,
      status: "reserved",
      reservedAt: FieldValue.serverTimestamp()
    });

    return receipt;
  });
}

function isUnregistered(error) {
  const details = error.response?.data?.error?.details;

  return Array.isArray(details) && details.some(
    (detail) =>
      detail["@type"] ===
        "type.googleapis.com/google.firebase.fcm.v1.FcmError" &&
      detail.errorCode === "UNREGISTERED"
  );
}

async function disableInvalidToken(db, registration, expectedToken) {
  await db.runTransaction(async (transaction) => {
    const current = await transaction.get(registration.ref);

    if (
      current.exists &&
      current.data().token === expectedToken
    ) {
      transaction.update(registration.ref, {
        enabled: false,
        invalidatedAt: FieldValue.serverTimestamp()
      });
    }
  });
}

async function main() {
  const args = process.argv.slice(2);

  if (args.some((arg) => arg !== "--send")) {
    throw new Error("Unsupported command argument.");
  }

  const send = args.includes("--send");
  const db = new Firestore({ projectId: PROJECT_ID });
  const today = calendarDate(new Date());

  const registrations = await db
    .collectionGroup("pushTokens")
    .limit(MAX_INSTALLATIONS + 1)
    .get();

  if (registrations.size > MAX_INSTALLATIONS) {
    throw new Error("Installation scan limit exceeded.");
  }

  const ownerCounts = new Map();
  const eligible = [];

  let enabledInstallations = 0;
  let invalidRegistrations = 0;

  // Complete all bounded scans before attempting any delivery.
  for (const registration of registrations.docs) {
    const segments = registration.ref.path.split("/");
    const data = registration.data();

    if (
      segments.length !== 4 ||
      segments[0] !== "users" ||
      segments[2] !== "pushTokens"
    ) {
      invalidRegistrations++;
      continue;
    }

    if (data.enabled !== true) continue;

    if (
      typeof data.token !== "string" ||
      data.token.trim() === ""
    ) {
      invalidRegistrations++;
      continue;
    }

    enabledInstallations++;

    const uid = segments[1];

    if (!ownerCounts.has(uid)) {
      const pantry = await db
        .collection("users")
        .doc(uid)
        .collection("pantry")
        .limit(MAX_PANTRY_ITEMS + 1)
        .get();

      if (pantry.size > MAX_PANTRY_ITEMS) {
        throw new Error("Pantry scan limit exceeded.");
      }

      ownerCounts.set(
        uid,
        pantry.docs.filter(
          (document) => needsReminder(document.data(), today)
        ).length
      );
    }

    if (ownerCounts.get(uid) > 0) {
      eligible.push({ registration, token: data.token });
    }
  }

  let attempted = 0;
  let accepted = 0;
  let skipped = 0;
  let failedOrUncertain = 0;

  if (send && eligible.length > 0) {
    const auth = new GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/cloud-platform"]
    });

    const client = await auth.getClient();

    for (const entry of eligible) {
      if (attempted >= MAX_SEND_ATTEMPTS) break;

      const receipt = await reserveAttempt(
        db,
        entry.registration,
        entry.token,
        today
      );

      if (receipt === null) {
        skipped++;
        continue;
      }

      attempted++;

      try {
        await client.request({
          url:
            `https://fcm.googleapis.com/v1/projects/` +
            `${PROJECT_ID}/messages:send`,
          method: "POST",
          data: {
            message: notificationMessage(entry.token, today)
          },
          timeout: 15000,
          retry: false
        });
      } catch (error) {
        failedOrUncertain++;

        await receipt.update({
          status: "failed-or-uncertain",
          finishedAt: FieldValue.serverTimestamp()
        });

        if (isUnregistered(error)) {
          await disableInvalidToken(
            db,
            entry.registration,
            entry.token
          );
        }

        // Keep the reservation. Do not automatically retry today.
        continue;
      }

      accepted++;

      // FCM acceptance does not prove display on the device.
      await receipt.update({
        status: "accepted-by-fcm",
        finishedAt: FieldValue.serverTimestamp()
      });
    }
  }

  console.log(JSON.stringify({
    mode: send ? "send" : "dry-run",
    calendarDate: today,
    timeZone: TIME_ZONE,
    soonThresholdDays: SOON_DAYS,
    enabledInstallations,
    accountsChecked: ownerCounts.size,
    installationsThatWouldReceiveReminder: eligible.length,
    invalidRegistrations,
    sendAttemptLimit: MAX_SEND_ATTEMPTS,
    attemptsReserved: attempted,
    messagesAcceptedByFcm: accepted,
    skippedExistingReservationOrChangedRegistration: skipped,
    failedOrUncertain,
    messagesSent: accepted
  }, null, 2));

  if (failedOrUncertain > 0) {
    process.exitCode = 1;
  }
}

if (require.main === module) {
  main().catch(() => {
    // Do not log credentials, tokens, account IDs or grocery contents.
    console.error(
      "Reminder job failed. Check authentication, permissions, " +
      "scan limits and delivery records. Reserved attempts are not retried."
    );
    process.exitCode = 1;
  });
}

module.exports = {
  calendarDate,
  dateNumber,
  needsReminder,
  deliveryId,
  notificationMessage,
  reserveAttempt
};