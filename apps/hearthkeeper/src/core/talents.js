// Talent arithmetic.
//
// Forever adds a 16-point milestone to the familiar 11/21/31 tiers, and that single number
// decides a lot about this beta: talent points start at level 10, one per level, so 16 points
// means level 25 — reachable only after the cap moves to 30. A tester who never passes the
// phase 1 cap of 20 will never see the headline talent change at all.
//
// Per-talent data is deliberately absent. It is not public, it will churn every build, and a
// companion that guesses at it is worse than one that admits the gap.

export function talentPointsAtLevel(level, talents) {
  const firstLevel = talents?.firstTalentLevel ?? 10;
  const perLevel = talents?.pointsPerLevel ?? 1;
  if (!Number.isFinite(level) || level < firstLevel) return 0;
  return (level - firstLevel + 1) * perLevel;
}

export function levelForTalentPoints(points, talents) {
  const firstLevel = talents?.firstTalentLevel ?? 10;
  const perLevel = talents?.pointsPerLevel ?? 1;
  if (!Number.isFinite(points) || points <= 0) return firstLevel;
  return firstLevel + Math.ceil(points / perLevel) - 1;
}

/**
 * Each talent milestone against the beta's phase schedule: the level it needs, the first
 * phase that can reach it, and whether the beta ever gets there.
 */
export function milestoneSchedule(pack) {
  const talents = pack?.talents ?? {};
  const milestones = talents.milestones ?? [];
  const phases = (pack?.beta?.phases ?? []).filter((phase) => Number.isFinite(phase?.levelCap));

  return milestones
    .filter((milestone) => Number.isFinite(milestone?.points))
    .slice()
    .sort((a, b) => a.points - b.points)
    .map((milestone) => {
      const requiredLevel = levelForTalentPoints(milestone.points, talents);
      const phase = phases.find((candidate) => candidate.levelCap >= requiredLevel) ?? null;
      return {
        ...milestone,
        requiredLevel,
        phase,
        phaseId: phase?.id ?? null,
        testableInBeta: Boolean(phase),
      };
    });
}

/**
 * Check a saved build against a character's level.
 * `build.trees` is { treeName: points } — tree names, not talent names, because the trees are
 * the part of the data that is actually public.
 */
export function validateBuild(build, level, talents) {
  const available = talentPointsAtLevel(level, talents);
  const trees = build?.trees ?? {};
  const entries = Object.entries(trees).map(([name, points]) => [name, Number(points) || 0]);
  const spent = entries.reduce((total, [, points]) => total + points, 0);
  const negative = entries.filter(([, points]) => points < 0).map(([name]) => name);

  const milestones = (talents?.milestones ?? [])
    .filter((milestone) => Number.isFinite(milestone?.points))
    .slice()
    .sort((a, b) => a.points - b.points);

  const reached = entries.map(([name, points]) => ({
    tree: name,
    points,
    milestonesReached: milestones.filter((milestone) => points >= milestone.points).map((m) => m.points),
    nextMilestone: milestones.find((milestone) => points < milestone.points)?.points ?? null,
  }));

  const errors = [];
  if (negative.length) errors.push(`Negative points in ${negative.join(', ')}.`);
  if (spent > available) errors.push(`${spent} points spent but only ${available} available at level ${level}.`);

  return {
    available,
    spent,
    remaining: available - spent,
    valid: errors.length === 0,
    errors,
    trees: reached,
  };
}
