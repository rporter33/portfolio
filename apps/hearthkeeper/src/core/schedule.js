// Where the beta is today: which phase is live, what the level cap is, how long is left.
// The whole app keys off this — content that is out of reach of the current cap is not
// "unfinished testing", it is content nobody can test yet, and those should never look alike.

import { daysBetween, isValidDay } from './dates.js';

/** Phases sorted by start day, ignoring malformed entries. */
export function orderedPhases(pack) {
  const phases = pack?.beta?.phases ?? [];
  return phases
    .filter((phase) => isValidDay(phase?.startsOn))
    .slice()
    .sort((a, b) => daysBetween(b.startsOn, a.startsOn));
}

/**
 * Resolve the beta's state on a given day.
 * status: 'before' | 'live' | 'ended' | 'unknown'
 */
export function resolveSchedule(pack, day) {
  const beta = pack?.beta;
  const phases = orderedPhases(pack);
  if (!beta || !isValidDay(day) || phases.length === 0) {
    return { status: 'unknown', phase: null, nextPhase: null, levelCap: null };
  }

  const startsOn = beta.startsOn ?? phases[0].startsOn;
  const endsOn = beta.endsOn ?? null;

  if (daysBetween(day, startsOn) > 0) {
    return {
      status: 'before',
      phase: null,
      nextPhase: phases[0],
      levelCap: null,
      startsOn,
      endsOn,
      daysUntilStart: daysBetween(day, startsOn),
      daysRemaining: endsOn ? daysBetween(day, endsOn) : null,
    };
  }

  if (endsOn && daysBetween(day, endsOn) < 0) {
    return {
      status: 'ended',
      phase: phases[phases.length - 1],
      nextPhase: null,
      levelCap: phases[phases.length - 1].levelCap ?? null,
      startsOn,
      endsOn,
      daysUntilStart: 0,
      daysRemaining: 0,
      launchesOn: beta.launchesOn ?? null,
      daysUntilLaunch: beta.launchesOn ? daysBetween(day, beta.launchesOn) : null,
    };
  }

  let current = phases[0];
  let next = null;
  for (const phase of phases) {
    if (daysBetween(phase.startsOn, day) >= 0) current = phase;
    else if (!next) next = phase;
  }

  return {
    status: 'live',
    phase: current,
    nextPhase: next,
    levelCap: current.levelCap ?? null,
    startsOn,
    endsOn,
    daysUntilStart: 0,
    daysRemaining: endsOn ? daysBetween(day, endsOn) : null,
    daysUntilNextPhase: next ? daysBetween(day, next.startsOn) : null,
    launchesOn: beta.launchesOn ?? null,
    daysUntilLaunch: beta.launchesOn ? daysBetween(day, beta.launchesOn) : null,
  };
}

/** The highest cap any beta phase will reach — the real ceiling on what is testable at all. */
export function maxBetaLevelCap(pack) {
  const caps = orderedPhases(pack)
    .map((phase) => phase.levelCap)
    .filter((cap) => Number.isFinite(cap));
  return caps.length ? Math.max(...caps) : null;
}

/** The first phase whose cap reaches `level`, or null if the beta never gets there. */
export function phaseReaching(pack, level) {
  if (!Number.isFinite(level)) return null;
  return orderedPhases(pack).find((phase) => Number.isFinite(phase.levelCap) && phase.levelCap >= level) ?? null;
}
