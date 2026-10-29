"use strict";

const { Firestore } = require("@google-cloud/firestore");

const PROJECT_ID = "faithful-pantry";
const TIME_ZONE = "Europe/London";
const SOON_DAYS = 3;

const MAX_INSTALLATIONS = 100;
const MAX_PANTRY_ITEMS = 1000;

function calendarDate(now) {
  const parts = new Intl.DateTimeFormat("en-GB", {
    timeZone: TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit"
  }).formatToParts(now);

  const get = (type) => parts.find((part) => part.type === type).value;

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

async function main() {
  if (process.argv.includes("--send")) {
    throw new Error("Sending is not implemented in this dry-run version.");
  }

  const db = new Firestore({ projectId: PROJECT_ID });
  const today = calendarDate(new Date());

  // Parent user documents need not exist for this query to find
  // registration documents stored in their subcollections.
  const registrations = await db
    .collectionGroup("pushTokens")
    .limit(MAX_INSTALLATIONS + 1)
    .get();

  if (registrations.size > MAX_INSTALLATIONS) {
    throw new Error("Installation scan limit exceeded; no messages sent.");
  }

  const ownerCounts = new Map();

  let enabledInstallations = 0;
  let eligibleInstallations = 0;
  let invalidRegistrations = 0;

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

    if (typeof data.token !== "string" || data.token.trim() === "") {
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
        throw new Error("Pantry scan limit exceeded; no messages sent.");
      }

      const count = pantry.docs.filter(
        (document) => needsReminder(document.data(), today)
      ).length;

      ownerCounts.set(uid, count);
    }

    if (ownerCounts.get(uid) > 0) {
      eligibleInstallations++;
    }
  }

  console.log(JSON.stringify({
    mode: "dry-run",
    calendarDate: today,
    timeZone: TIME_ZONE,
    soonThresholdDays: SOON_DAYS,
    enabledInstallations,
    accountsChecked: ownerCounts.size,
    installationsThatWouldReceiveReminder: eligibleInstallations,
    invalidRegistrations,
    messagesSent: 0
  }, null, 2));
}

if (require.main === module) {
  main().catch(() => {
    // Avoid printing credentials, document contents or delivery tokens.
    console.error(
      "Reminder dry run failed. Check authentication, permissions and scan limits."
    );
    process.exitCode = 1;
  });
}

module.exports = { calendarDate, dateNumber, needsReminder };