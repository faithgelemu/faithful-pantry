"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  deliveryId,
  notificationMessage,
  reserveAttempt
} = require("./expiry-reminders.cjs");

const path = "users/test-owner/pushTokens/test-registration";
const today = "2026-10-29";
const testToken = "synthetic-test-token";

function fakeDatabase(registrationData) {
  const records = new Map();

  if (registrationData !== null) {
    records.set(path, registrationData);
  }

  const db = {
    collection: (name) => ({
      doc: (id) => ({ path: `${name}/${id}` })
    }),

    runTransaction: async (callback) => {
      const writes = [];

      const result = await callback({
        get: async (ref) => ({
          exists: records.has(ref.path),
          data: () => records.get(ref.path)
        }),

        create: (ref, data) => {
          if (records.has(ref.path)) {
            throw new Error("Document already exists.");
          }

          writes.push([ref.path, data]);
        }
      });

      for (const [key, value] of writes) {
        records.set(key, value);
      }

      return result;
    }
  };

  return { db, records };
}

test("same registration and day produce the same reservation ID", () => {
  assert.equal(deliveryId(path, today), deliveryId(path, today));

  assert.notEqual(
    deliveryId(path, today),
    deliveryId(path, "2026-10-30")
  );

  assert.notEqual(
    deliveryId(path, today),
    deliveryId("users/other/pushTokens/other", today)
  );
});

test("second attempt is blocked by the first reservation", async () => {
  const { db } = fakeDatabase({
    enabled: true,
    token: testToken
  });

  const registration = { ref: { path } };

  const first = await reserveAttempt(
    db, registration, testToken, today
  );

  const second = await reserveAttempt(
    db, registration, testToken, today
  );

  assert.notEqual(first, null);
  assert.equal(second, null);
});

test("disabled, deleted or changed registrations cannot reserve", async () => {
  for (const data of [
    null,
    { enabled: false, token: testToken },
    { enabled: true, token: "replacement-token" }
  ]) {
    const { db, records } = fakeDatabase(data);

    const result = await reserveAttempt(
      db,
      { ref: { path } },
      testToken,
      today
    );

    assert.equal(result, null);

    const receipts = [...records.keys()].filter(
      (key) => key.startsWith("_pushReminderDeliveries/")
    );

    assert.equal(receipts.length, 0);
  }
});

test("uncertain delivery remains blocked for the same day", async () => {
  const { db, records } = fakeDatabase({
    enabled: true,
    token: testToken
  });

  const receiptPath =
    `_pushReminderDeliveries/${deliveryId(path, today)}`;

  records.set(receiptPath, {
    status: "failed-or-uncertain"
  });

  const result = await reserveAttempt(
    db,
    { ref: { path } },
    testToken,
    today
  );

  assert.equal(result, null);
});

test("notification uses generic wording and the HTTPS app link", () => {
  const message = notificationMessage(testToken, today);

  assert.equal(message.token, testToken);
  assert.equal(
    message.webpush.fcm_options.link,
    "https://faithful-pantry.web.app/"
  );
  assert.equal(message.webpush.headers.TTL, "3600");
  assert.equal(
    message.notification.body,
    "Some groceries are approaching their recorded expiry dates. " +
      "Open Faithful Pantry to review them."
  );
});