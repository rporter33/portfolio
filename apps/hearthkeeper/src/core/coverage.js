// Test coverage.
//
// The honest question a beta tester can't answer from memory is "what have I not looked at?"
// — and the useless version of that question counts content the current phase cannot reach.
// So every content entry lands in one of three buckets: touched, reachable and untouched, or
// out of reach of this phase. Only the middle bucket is work.

import { contentEntries, priorityCombos } from './pack.js';
import { maxBetaLevelCap, phaseReaching } from './schedule.js';

export const REACH = { REACHABLE: 'reachable', LATER_PHASE: 'later-phase', BEYOND_BETA: 'beyond-beta', UNKNOWN: 'unknown' };

/**
 * Can a character at `levelCap` get into this entry at all?
 * A null cap means no phase is live — before the beta opens or after it closes — which is a
 * different answer from "a later phase reaches it", and the note says so.
 */
export function reachability(entry, pack, levelCap) {
  if (entry.collection === 'raids') return { reach: REACH.BEYOND_BETA, why: 'No raid testing during the beta.' };
  if (!Number.isFinite(entry.minLevel)) return { reach: REACH.UNKNOWN, why: 'Level range unannounced.' };
  if (Number.isFinite(levelCap) && entry.minLevel <= levelCap) return { reach: REACH.REACHABLE, why: null };

  const phase = phaseReaching(pack, entry.minLevel);
  if (phase) {
    const why = Number.isFinite(levelCap)
      ? `Needs level ${entry.minLevel} — ${phase.name} raises the cap to ${phase.levelCap}.`
      : `No phase is live. ${phase.name} opens at a cap of ${phase.levelCap}, which reaches this.`;
    return { reach: REACH.LATER_PHASE, why, phase };
  }
  const ceiling = maxBetaLevelCap(pack);
  return { reach: REACH.BEYOND_BETA, why: `Needs level ${entry.minLevel}; the beta caps at ${ceiling ?? '?'}.` };
}

export function computeCoverage({ pack, findings = [], characters = [], levelCap = null }) {
  const touchedIds = new Set(findings.map((finding) => finding.contentId).filter(Boolean));

  const entries = contentEntries(pack).map((entry) => {
    const { reach, why, phase } = reachability(entry, pack, levelCap);
    const entryFindings = findings.filter((finding) => finding.contentId === entry.id);
    return {
      ...entry,
      reach,
      reachNote: why,
      phase: phase ?? null,
      touched: touchedIds.has(entry.id),
      findingCount: entryFindings.length,
      blockerCount: entryFindings.filter((finding) => finding.severity === 'blocker').length,
    };
  });

  const reachable = entries.filter((entry) => entry.reach === REACH.REACHABLE);
  const untouched = reachable.filter((entry) => !entry.touched);

  return {
    entries,
    reachable,
    untouched,
    outOfReach: entries.filter((entry) => entry.reach === REACH.LATER_PHASE || entry.reach === REACH.BEYOND_BETA),
    unknownReach: entries.filter((entry) => entry.reach === REACH.UNKNOWN),
    touchedCount: reachable.filter((entry) => entry.touched).length,
    reachableCount: reachable.length,
    percent: reachable.length ? Math.round((reachable.filter((entry) => entry.touched).length / reachable.length) * 100) : null,
    combos: comboCoverage({ pack, characters, findings }),
  };
}

/** The new race and the six new race/class pairs — the part of this patch that most needs eyes. */
export function comboCoverage({ pack, characters = [], findings = [] }) {
  const rows = priorityCombos(pack).map((combo) => {
    const played = characters.filter(
      (character) => character.raceId === combo.raceId && character.className === combo.className,
    );
    const highestLevel = played.reduce((max, character) => Math.max(max, character.level ?? 0), 0);
    const reported = findings.filter((finding) => played.some((character) => character.id === finding.characterId));
    return {
      ...combo,
      played: played.length > 0,
      characterCount: played.length,
      highestLevel: highestLevel || null,
      findingCount: reported.length,
    };
  });

  return {
    rows,
    playedCount: rows.filter((row) => row.played).length,
    total: rows.length,
  };
}

/**
 * What to do next: reachable content with nothing logged against it, then unplayed priority
 * combos. Blockers first — a zone with a blocker is worth a second pass before a fresh one.
 */
export function suggestNext(coverage, limit = 5) {
  const fromContent = coverage.untouched.map((entry) => ({
    kind: 'content',
    id: entry.id,
    label: entry.name,
    detail: entry.collection === 'dungeons' ? 'Dungeon with no findings logged' : 'Zone with no findings logged',
  }));
  const fromCombos = (coverage.combos?.rows ?? [])
    .filter((row) => !row.played)
    .map((row) => ({
      kind: 'combo',
      id: `${row.raceId}:${row.className}`,
      label: `${row.raceName} ${row.className}`,
      detail: row.reason === 'new race' ? 'New race, never rolled' : 'New race/class combination, never rolled',
    }));
  return [...fromContent, ...fromCombos].slice(0, limit);
}
