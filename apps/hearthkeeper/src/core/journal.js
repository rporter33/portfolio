// The field journal: what you found, where, on which build.
//
// The thing that actually goes wrong in a beta is not finding bugs — it is losing them. You
// hit three problems in a dungeon run, keep playing, and by the time you alt-tab out you can
// reconstruct one of them. So capture is cheap (a title is enough) and enrichment is optional.

import { optionalNumber } from './values.js';

export const FINDING_TYPES = ['bug', 'quest', 'tuning', 'text', 'ui', 'feedback'];
export const SEVERITIES = ['blocker', 'major', 'minor', 'polish'];
export const STATUSES = ['open', 'reported', 'resolved', 'wont-fix'];

const SEVERITY_ORDER = Object.fromEntries(SEVERITIES.map((severity, index) => [severity, index]));

export function createFinding(input = {}, options = {}) {
  const now = options.now ?? new Date().toISOString();
  return {
    id: options.id ?? `f_${Math.random().toString(36).slice(2, 10)}`,
    createdAt: now,
    updatedAt: now,
    title: String(input.title ?? '').trim(),
    type: FINDING_TYPES.includes(input.type) ? input.type : 'bug',
    severity: SEVERITIES.includes(input.severity) ? input.severity : 'minor',
    status: STATUSES.includes(input.status) ? input.status : 'open',
    gameBuild: input.gameBuild ?? options.gameBuild ?? null,
    contentId: input.contentId ?? null,
    contentName: input.contentName ?? null,
    characterId: input.characterId ?? null,
    level: optionalNumber(input.level),
    steps: String(input.steps ?? '').trim(),
    expected: String(input.expected ?? '').trim(),
    actual: String(input.actual ?? '').trim(),
    reproducible: input.reproducible ?? 'unknown',
    tags: normalizeTags(input.tags),
  };
}

export function normalizeTags(tags) {
  const list = Array.isArray(tags) ? tags : String(tags ?? '').split(',');
  return [...new Set(list.map((tag) => String(tag).trim().toLowerCase()).filter(Boolean))];
}

export function validateFinding(finding) {
  const errors = [];
  if (!finding?.title) errors.push('A finding needs a title.');
  if (finding?.title && finding.title.length > 160) errors.push('Title is over 160 characters.');
  if (!FINDING_TYPES.includes(finding?.type)) errors.push(`Unknown type: ${finding?.type}.`);
  if (!SEVERITIES.includes(finding?.severity)) errors.push(`Unknown severity: ${finding?.severity}.`);
  if (!STATUSES.includes(finding?.status)) errors.push(`Unknown status: ${finding?.status}.`);
  if (finding?.level != null && (!Number.isFinite(finding.level) || finding.level < 1)) {
    errors.push('Level must be a positive number.');
  }
  return { valid: errors.length === 0, errors };
}

export function updateFinding(finding, changes, options = {}) {
  const merged = { ...finding, ...changes };
  return {
    ...createFinding(merged, { id: finding.id, now: finding.createdAt }),
    createdAt: finding.createdAt,
    updatedAt: options.now ?? new Date().toISOString(),
  };
}

/** Normalized key used to catch "did I already write this one down?" */
export function dedupeKey(finding) {
  const title = String(finding?.title ?? '')
    .toLowerCase()
    .replace(/[^a-z0-9 ]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  return `${finding?.contentId ?? 'none'}::${title}`;
}

export function findDuplicates(findings, candidate) {
  const key = dedupeKey(candidate);
  return (findings ?? []).filter((finding) => finding.id !== candidate.id && dedupeKey(finding) === key);
}

export function filterFindings(findings, query = {}) {
  const text = String(query.text ?? '').trim().toLowerCase();
  return (findings ?? []).filter((finding) => {
    if (query.type && finding.type !== query.type) return false;
    if (query.severity && finding.severity !== query.severity) return false;
    if (query.status && finding.status !== query.status) return false;
    if (query.contentId && finding.contentId !== query.contentId) return false;
    if (query.gameBuild && finding.gameBuild !== query.gameBuild) return false;
    if (!text) return true;
    const haystack = [finding.title, finding.steps, finding.expected, finding.actual, finding.contentName, ...(finding.tags ?? [])]
      .join(' ')
      .toLowerCase();
    return haystack.includes(text);
  });
}

/** Worst first, then newest first — the order you would triage in. */
export function sortFindings(findings) {
  return (findings ?? []).slice().sort((a, b) => {
    const bySeverity = (SEVERITY_ORDER[a.severity] ?? 99) - (SEVERITY_ORDER[b.severity] ?? 99);
    if (bySeverity !== 0) return bySeverity;
    return String(b.createdAt).localeCompare(String(a.createdAt));
  });
}

export function summarize(findings) {
  const counts = { total: 0, byType: {}, bySeverity: {}, byStatus: {} };
  for (const finding of findings ?? []) {
    counts.total += 1;
    counts.byType[finding.type] = (counts.byType[finding.type] ?? 0) + 1;
    counts.bySeverity[finding.severity] = (counts.bySeverity[finding.severity] ?? 0) + 1;
    counts.byStatus[finding.status] = (counts.byStatus[finding.status] ?? 0) + 1;
  }
  return counts;
}
