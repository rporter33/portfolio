import { describe, expect, it } from 'vitest';
import pack from '../../data/pack.2026-09-17.json';
import { REACH, comboCoverage, computeCoverage, reachability, suggestNext } from '../coverage.js';
import { contentById } from '../pack.js';
import { createFinding } from '../journal.js';
import { createCharacter } from '../roster.js';

const entry = (id) => ({ ...contentById(pack, id), collection: contentById(pack, id).kind === 'raid' ? 'raids' : 'zones' });

describe('reachability', () => {
  it('calls a level 1 zone reachable at the phase 1 cap', () => {
    expect(reachability({ ...entry('zephras-isle'), collection: 'zones' }, pack, 20).reach).toBe(REACH.REACHABLE);
  });

  it('points a level 30 zone at the phase that unlocks it', () => {
    const result = reachability({ ...entry('the-riverglades'), collection: 'zones' }, pack, 20);
    expect(result.reach).toBe(REACH.LATER_PHASE);
    expect(result.phase.id).toBe('phase-2');
  });

  it('marks raids as out of scope for this beta entirely', () => {
    expect(reachability({ ...entry('hyjal-summit'), collection: 'raids' }, pack, 30).reach).toBe(REACH.BEYOND_BETA);
  });

  it('keeps unannounced level ranges out of the untested pile', () => {
    expect(reachability({ ...entry('mount-hyjal'), collection: 'zones' }, pack, 30).reach).toBe(REACH.UNKNOWN);
  });
});

describe('computeCoverage', () => {
  const findings = [
    createFinding({ title: 'Wind wall clips', contentId: 'zephras-isle', severity: 'blocker' }, { id: 'f1', now: 'a' }),
  ];

  it('scores only what the current cap can actually reach', () => {
    const coverage = computeCoverage({ pack, findings, levelCap: 20 });
    expect(coverage.reachableCount).toBe(1);
    expect(coverage.touchedCount).toBe(1);
    expect(coverage.percent).toBe(100);
    expect(coverage.outOfReach.map((item) => item.id)).toContain('the-riverglades');
  });

  it('adds the phase 2 zone to the work list once the cap rises', () => {
    const coverage = computeCoverage({ pack, findings, levelCap: 30 });
    expect(coverage.reachableCount).toBe(2);
    expect(coverage.percent).toBe(50);
    expect(coverage.untouched.map((item) => item.id)).toEqual(['the-riverglades']);
  });

  it('carries blocker counts through to the entry', () => {
    const coverage = computeCoverage({ pack, findings, levelCap: 20 });
    expect(coverage.entries.find((item) => item.id === 'zephras-isle').blockerCount).toBe(1);
  });
});

describe('comboCoverage', () => {
  const characters = [createCharacter({ name: 'Sarkoth', raceId: 'undead', className: 'Paladin', level: 12 }, { id: 'c1' })];
  const findings = [createFinding({ title: 'Seal missing', characterId: 'c1' }, { id: 'f1' })];

  it('counts a new pairing as covered once one has been rolled', () => {
    const coverage = comboCoverage({ pack, characters, findings });
    const row = coverage.rows.find((item) => item.raceId === 'undead' && item.className === 'Paladin');
    expect(row.played).toBe(true);
    expect(row.highestLevel).toBe(12);
    expect(row.findingCount).toBe(1);
    expect(coverage.playedCount).toBe(1);
  });
});

describe('suggestNext', () => {
  it('names reachable-but-untouched content before unrolled combos', () => {
    const coverage = computeCoverage({ pack, findings: [], characters: [], levelCap: 30 });
    const suggestions = suggestNext(coverage, 3);
    expect(suggestions[0].kind).toBe('content');
    expect(suggestions.some((item) => item.kind === 'combo')).toBe(true);
    expect(suggestions).toHaveLength(3);
  });
});

describe('before the beta opens', () => {
  it('says no phase is live rather than blaming a later phase', () => {
    const result = reachability({ ...entry('zephras-isle'), collection: 'zones' }, pack, null);
    expect(result.reach).toBe(REACH.LATER_PHASE);
    expect(result.why).toContain('No phase is live');
    expect(result.phase.id).toBe('phase-1');
  });

  it('scores nothing as reachable, rather than scoring 0%', () => {
    const coverage = computeCoverage({ pack, findings: [], levelCap: null });
    expect(coverage.reachableCount).toBe(0);
    expect(coverage.percent).toBeNull();
  });
});
