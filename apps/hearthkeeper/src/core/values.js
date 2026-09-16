// Coercion helpers.
//
// `Number(null)` is 0 and `Number('')` is 0, which is how an optional level silently becomes
// a real level 0 and then fails its own validator on the next import. Absent stays absent.

export function optionalNumber(value) {
  if (value === null || value === undefined || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export function numberOr(value, fallback) {
  const parsed = optionalNumber(value);
  return parsed === null ? fallback : parsed;
}
