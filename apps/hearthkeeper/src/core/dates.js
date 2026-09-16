// Date helpers. Everything in the app is a plain YYYY-MM-DD string: beta schedules are
// announced as calendar days, and doing the arithmetic in UTC keeps a tester in Denver
// and a tester in Sydney from seeing different phases on the same day.

const DAY_MS = 86400000;

export function toUTC(day) {
  if (day instanceof Date) return Date.UTC(day.getUTCFullYear(), day.getUTCMonth(), day.getUTCDate());
  const match = /^(\d{4})-(\d{2})-(\d{2})/.exec(String(day));
  if (!match) return NaN;
  const [, y, m, d] = match;
  return Date.UTC(Number(y), Number(m) - 1, Number(d));
}

export function isValidDay(day) {
  return Number.isFinite(toUTC(day));
}

/** Whole days from `from` to `to`; negative when `to` is earlier. */
export function daysBetween(from, to) {
  const a = toUTC(from);
  const b = toUTC(to);
  if (!Number.isFinite(a) || !Number.isFinite(b)) return NaN;
  return Math.round((b - a) / DAY_MS);
}

export function addDays(day, count) {
  const base = toUTC(day);
  if (!Number.isFinite(base)) return null;
  return new Date(base + count * DAY_MS).toISOString().slice(0, 10);
}

export function today(now = new Date()) {
  return new Date(now).toISOString().slice(0, 10);
}

export function formatDay(day) {
  const base = toUTC(day);
  if (!Number.isFinite(base)) return String(day ?? '');
  return new Date(base).toLocaleDateString(undefined, {
    timeZone: 'UTC',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}
