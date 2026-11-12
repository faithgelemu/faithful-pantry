
"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  calendarDate,
  dateNumber,
  needsReminder,
  reminderDaysFromSettings
} = require("./expiry-reminders.cjs");

const today = "2026-10-29";

function item(overrides = {}) {
  return {
    status: "active",
    currentQuantity: 2,
    expiryDate: today,
    ...overrides
  };
}

function dateAfter(days) {
  const date = new Date(`${today}T00:00:00Z`);
  date.setUTCDate(date.getUTCDate() + days);
  return date.toISOString().slice(0, 10);
}

test("includes today, tomorrow and the three-day default boundary", () => {
  for (const expiryDate of [
    "2026-10-29",
    "2026-10-30",
    "2026-11-01",
  ]) {
    assert.equal(
      needsReminder(item({ expiryDate }), today),
      true,
      expiryDate
    );
  }
});

test("supports every reminder period from one to seven days", () => {
  for (let reminderDays = 1; reminderDays <= 7; reminderDays++) {
    const boundaryDate = dateAfter(reminderDays);
    const beyondBoundaryDate = dateAfter(reminderDays + 1);

    assert.equal(
      needsReminder(
        item({ expiryDate: boundaryDate }),
        today,
        reminderDays
      ),
      true,
      `${reminderDays}-day reminder should include its boundary`
    );

    assert.equal(
      needsReminder(
        item({ expiryDate: beyondBoundaryDate }),
        today,
        reminderDays
      ),
      false,
      `${reminderDays}-day reminder should exclude the next day`
    );
  }
});

test("includes items expiring today for every reminder period", () => {
  for (let reminderDays = 1; reminderDays <= 7; reminderDays++) {
    assert.equal(
      needsReminder(item(), today, reminderDays),
      true,
      `${reminderDays}-day reminder should include today`
    );
  }
});

test("defaults to three days when no reminder period is supplied", () => {
  assert.equal(
    needsReminder(item({ expiryDate: dateAfter(3) }), today),
    true
  );

  assert.equal(
    needsReminder(item({ expiryDate: dateAfter(4) }), today),
    false
  );
});

test("uses three days when an invalid calculation period is supplied", () => {
  for (const invalidDays of [0, 8, -1, 3.5, "7", null]) {
    assert.equal(
      needsReminder(item({ expiryDate: dateAfter(3) }), today, invalidDays),
      true,
      `Invalid period ${String(invalidDays)} should use the three-day default`
    );

    assert.equal(
      needsReminder(item({ expiryDate: dateAfter(4) }), today, invalidDays),
      false,
      `Invalid period ${String(invalidDays)} should not exceed three days`
    );
  }
});

test("reads valid reminder periods from account settings", () => {
  for (let reminderDays = 1; reminderDays <= 7; reminderDays++) {
    assert.equal(
      reminderDaysFromSettings({ expiryReminderDays: reminderDays }),
      reminderDays
    );
  }
});

test("defaults missing or invalid account settings to three days", () => {
  for (const settings of [
    undefined,
    null,
    {},
    { expiryReminderDays: null },
    { expiryReminderDays: 0 },
    { expiryReminderDays: 8 },
    { expiryReminderDays: -1 },
    { expiryReminderDays: 3.5 },
    { expiryReminderDays: "7" }
  ]) {
    assert.equal(
      reminderDaysFromSettings(settings),
      3
    );
  }
});

test("excludes expired items and dates beyond the default threshold", () => {
  for (const expiryDate of ["2026-10-28", "2026-11-02"]) {
    assert.equal(
      needsReminder(item({ expiryDate }), today),
      false,
      expiryDate
    );
  }
});

test("excludes used, wasted and empty inventory", () => {
  for (const overrides of [
    { status: "used" },
    { status: "wasted" },
    { currentQuantity: 0 },
    { currentQuantity: -1 },
    { currentQuantity: "2" }
  ]) {
    assert.equal(needsReminder(item(overrides), today), false);
  }
});

test("rejects missing and impossible dates", () => {
  for (const value of [
    null,
    "",
    "29/10/2026",
    "2026-02-29",
    "2026-04-31",
    "2026-13-01"
  ]) {
    assert.equal(dateNumber(value), null);
    assert.equal(
      needsReminder(item({ expiryDate: value }), today),
      false
    );
  }
});

test("accepts a valid leap day", () => {
  assert.notEqual(dateNumber("2028-02-29"), null);
});

test("uses London calendar dates during British Summer Time", () => {
  assert.equal(
    calendarDate(new Date("2026-07-01T23:30:00Z")),
    "2026-07-02"
  );
});

test("uses London calendar dates during winter", () => {
  assert.equal(
    calendarDate(new Date("2026-12-01T23:30:00Z")),
    "2026-12-01"
  );
});
