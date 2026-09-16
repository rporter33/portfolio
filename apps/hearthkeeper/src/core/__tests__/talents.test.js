import { describe, expect, it } from 'vitest';
import pack from '../../data/pack.2026-09-17.json';
import { levelForTalentPoints, milestoneSchedule, talentPointsAtLevel, validateBuild } from '../talents.js';

const talents = pack.talents;

describe('talent points', () => {
  it('starts at level 10 and adds one per level', () => {
    expect(talentPointsAtLevel(9, talents)).toBe(0);
    expect(talentPointsAtLevel(10, talents)).toBe(1);
    expect(talentPointsAtLevel(20, talents)).toBe(11);
    expect(talentPointsAtLevel(30, talents)).toBe(21);
    expect(talentPointsAtLevel(60, talents)).toBe(51);
  });

  it('inverts to the level a milestone needs', () => {
    expect(levelForTalentPoints(11, talents)).toBe(20);
    expect(levelForTalentPoints(16, talents)).toBe(25);
    expect(levelForTalentPoints(31, talents)).toBe(40);
  });
});

describe('milestoneSchedule', () => {
  const schedule = milestoneSchedule(pack);

  it('puts the phase 1 cap exactly on the 11-point tier', () => {
    const eleven = schedule.find((milestone) => milestone.points === 11);
    expect(eleven.requiredLevel).toBe(20);
    expect(eleven.phaseId).toBe('phase-1');
  });

  it("holds Forever's new 16-point tier back to phase 2", () => {
    const sixteen = schedule.find((milestone) => milestone.points === 16);
    expect(sixteen.requiredLevel).toBe(25);
    expect(sixteen.phaseId).toBe('phase-2');
    expect(sixteen.testableInBeta).toBe(true);
  });

  it('marks the 31-point capstone as untestable during the beta', () => {
    const capstone = schedule.find((milestone) => milestone.points === 31);
    expect(capstone.requiredLevel).toBe(40);
    expect(capstone.testableInBeta).toBe(false);
  });
});

describe('validateBuild', () => {
  it('accepts a build inside the level budget and tracks tiers reached', () => {
    const result = validateBuild({ trees: { Elemental: 16, Restoration: 5 } }, 30, talents);
    expect(result.valid).toBe(true);
    expect(result.spent).toBe(21);
    expect(result.remaining).toBe(0);
    expect(result.trees.find((tree) => tree.tree === 'Elemental').milestonesReached).toEqual([11, 16]);
    expect(result.trees.find((tree) => tree.tree === 'Restoration').nextMilestone).toBe(11);
  });

  it('rejects overspending and negative allocations', () => {
    const overspent = validateBuild({ trees: { Fire: 20 } }, 20, talents);
    expect(overspent.valid).toBe(false);
    expect(overspent.errors[0]).toContain('only 11 available');
    expect(validateBuild({ trees: { Fire: -2 } }, 20, talents).valid).toBe(false);
  });
});

describe('talent trees', () => {
  it('offers three trees for every class in the pack', () => {
    for (const className of pack.classes) {
      expect(pack.talents.trees[className]).toHaveLength(3);
    }
  });

  it('labels tree names as carried over from Classic rather than announced', () => {
    expect(pack.talents.treesConfidence).toBe('carried-over');
  });
});
