import { describe, expect, it } from 'vitest';
import { addDays, daysBetween, isValidDay, today } from '../dates.js';

describe('dates', () => {
  it('counts whole days forward and backward', () => {
    expect(daysBetween('2026-09-17', '2026-10-21')).toBe(34);
    expect(daysBetween('2026-10-21', '2026-09-17')).toBe(-34);
    expect(daysBetween('2026-09-17', '2026-09-17')).toBe(0);
  });

  it('crosses a month and a DST boundary without drifting', () => {
    expect(daysBetween('2026-10-31', '2026-11-04')).toBe(4);
    expect(addDays('2026-09-30', 1)).toBe('2026-10-01');
  });

  it('rejects malformed days instead of guessing', () => {
    expect(isValidDay('not-a-day')).toBe(false);
    expect(Number.isNaN(daysBetween('nope', '2026-09-17'))).toBe(true);
  });

  it('reads a Date as its UTC calendar day', () => {
    expect(today(new Date('2026-09-16T23:30:00Z'))).toBe('2026-09-16');
  });
});
