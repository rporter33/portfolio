import { describe, expect, it } from 'vitest';
import {
  createFinding,
  dedupeKey,
  filterFindings,
  findDuplicates,
  sortFindings,
  summarize,
  updateFinding,
  validateFinding,
} from '../journal.js';

const at = (now) => ({ now, id: `id-${now}` });

describe('createFinding', () => {
  it('needs only a title and fills sane defaults', () => {
    const finding = createFinding({ title: '  Quest turn-in missing  ' }, at('2026-09-17T10:00:00Z'));
    expect(finding.title).toBe('Quest turn-in missing');
    expect(finding.type).toBe('bug');
    expect(finding.severity).toBe('minor');
    expect(finding.status).toBe('open');
    expect(finding.level).toBeNull();
  });

  it('falls back to defaults rather than storing an unknown type', () => {
    expect(createFinding({ title: 'x', type: 'catastrophe', severity: 'apocalyptic' }).type).toBe('bug');
  });

  it('stamps the build it was found on', () => {
    expect(createFinding({ title: 'x' }, { gameBuild: 'beta-phase-1' }).gameBuild).toBe('beta-phase-1');
  });

  it('normalizes tags from a comma string or an array', () => {
    expect(createFinding({ title: 'x', tags: 'Hyjal, hyjal ,  pathing ' }).tags).toEqual(['hyjal', 'pathing']);
    expect(createFinding({ title: 'x', tags: ['UI', 'ui'] }).tags).toEqual(['ui']);
  });
});

describe('validateFinding', () => {
  it('requires a title', () => {
    expect(validateFinding(createFinding({ title: '' })).errors).toContain('A finding needs a title.');
  });

  it('rejects an impossible level', () => {
    const finding = { ...createFinding({ title: 'x' }), level: -3 };
    expect(validateFinding(finding).valid).toBe(false);
  });
});

describe('updateFinding', () => {
  it('keeps the original id and creation time but moves updatedAt', () => {
    const original = createFinding({ title: 'Original' }, at('2026-09-17T10:00:00Z'));
    const edited = updateFinding(original, { severity: 'blocker' }, { now: '2026-09-18T09:00:00Z' });
    expect(edited.id).toBe(original.id);
    expect(edited.createdAt).toBe(original.createdAt);
    expect(edited.updatedAt).toBe('2026-09-18T09:00:00Z');
    expect(edited.severity).toBe('blocker');
  });
});

describe('duplicates', () => {
  it('matches the same report written with different punctuation in the same place', () => {
    const first = createFinding({ title: 'Wind Rider does not land!', contentId: 'zephras-isle' }, at('a'));
    const second = createFinding({ title: 'wind rider does not land', contentId: 'zephras-isle' }, at('b'));
    expect(dedupeKey(first)).toBe(dedupeKey(second));
    expect(findDuplicates([first], second)).toHaveLength(1);
  });

  it('does not match the same wording in a different zone', () => {
    const first = createFinding({ title: 'Mob leashes early', contentId: 'zephras-isle' }, at('a'));
    const second = createFinding({ title: 'Mob leashes early', contentId: 'mount-hyjal' }, at('b'));
    expect(findDuplicates([first], second)).toHaveLength(0);
  });
});

describe('filter and sort', () => {
  const findings = [
    createFinding({ title: 'Blocker in Dalaran', severity: 'blocker', contentId: 'city-of-dalaran' }, at('2026-09-17T10:00:00Z')),
    createFinding({ title: 'Typo in quest text', severity: 'polish', type: 'text' }, at('2026-09-18T10:00:00Z')),
    createFinding({ title: 'Pathing near the falls', severity: 'minor', tags: ['pathing'] }, at('2026-09-19T10:00:00Z')),
  ];

  it('filters by field and by free text across the whole entry', () => {
    expect(filterFindings(findings, { severity: 'blocker' })).toHaveLength(1);
    expect(filterFindings(findings, { type: 'text' })).toHaveLength(1);
    expect(filterFindings(findings, { text: 'pathing' })).toHaveLength(1);
    expect(filterFindings(findings, { contentId: 'city-of-dalaran' })).toHaveLength(1);
    expect(filterFindings(findings, {})).toHaveLength(3);
  });

  it('sorts worst first, then newest', () => {
    expect(sortFindings(findings).map((finding) => finding.severity)).toEqual(['blocker', 'minor', 'polish']);
  });

  it('summarizes counts for the dashboard', () => {
    const counts = summarize(findings);
    expect(counts.total).toBe(3);
    expect(counts.bySeverity.blocker).toBe(1);
    expect(counts.byStatus.open).toBe(3);
  });
});

describe('optional level', () => {
  it('keeps an unrecorded level absent instead of coercing it to 0', () => {
    // Number(null) and Number('') are both 0, which would make an untouched field look like a
    // real level 0 and then fail validation on the next import.
    for (const value of [null, undefined, '', 'twelve']) {
      const finding = createFinding({ title: 'x', level: value });
      expect(finding.level).toBeNull();
      expect(validateFinding(finding).valid).toBe(true);
    }
    expect(createFinding({ title: 'x', level: '17' }).level).toBe(17);
  });
});
