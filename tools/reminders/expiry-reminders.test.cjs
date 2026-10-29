"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");

const {
  calendarDate,
  dateNumber,
  needsReminder
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

test("includes today, tomorrow and the three-day boundary", () => {
  for (const expiryDate of [
    "2026-10-29",
    "2026-10-30",
    "2026-11-01"
  ]) {
    assert.equal(
      needsReminder(item({ expiryDate }), today),
      true,
      expiryDate
    );
  }
});

test("excludes expired items and dates beyond the threshold", () => {
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