import { describe, expect, it } from 'vitest';
import pack from '../../data/pack.2026-09-17.json';
import { createFinding } from '../journal.js';
import { createCharacter } from '../roster.js';
import { toDigest, toForumPost } from '../report.js';

const characters = [
  createCharacter({ name: 'Aelyn', raceId: 'skyborne-elf-horde', className: 'Shaman', level: 17 }, { id: 'c1' }),
];

const findings = [
  createFinding(
    {
      title: 'Skyborne flight form drops on zone edge',
      type: 'bug',
      severity: 'blocker',
      contentId: 'zephras-isle',
      contentName: 'Zephras Isle',
      level: 11,
      characterId: 'c1',
      gameBuild: 'beta-phase-1',
      steps: 'Fly to the south rim\n2) Cross the boundary',
      expected: 'Flight continues',
      actual: 'Character falls and dies',
      reproducible: 'always',
      tags: 'zephras, flight',
    },
    { id: 'f1', now: '2026-09-17T12:00:00Z' },
  ),
  createFinding(
    { title: 'Quest text calls the isle "Zephra"', type: 'text', severity: 'polish', gameBuild: 'beta-phase-1' },
    { id: 'f2', now: '2026-09-17T13:00:00Z' },
  ),
];

describe('toForumPost', () => {
  const post = toForumPost(findings, { pack, characters, day: '2026-09-18' });

  it('leads with the header, count and build stamp', () => {
    expect(post).toContain('# Forever beta feedback');
    expect(post).toContain('2 findings · build beta-phase-1 · logged through 2026-09-18');
  });

  it('groups by severity, worst first', () => {
    expect(post.indexOf('## Blocker (1)')).toBeLessThan(post.indexOf('## Polish (1)'));
  });

  it('renumbers pasted steps into a clean list', () => {
    expect(post).toContain('1. Fly to the south rim');
    expect(post).toContain('2. Cross the boundary');
  });

  it('carries the character that hit it', () => {
    expect(post).toContain('**Character:** Aelyn · Skyborne Elf (Elemental) · Shaman · level 17');
  });

  it('keeps expected and actual apart', () => {
    expect(post).toContain('**Expected:** Flight continues');
    expect(post).toContain('**Actual:** Character falls and dies');
  });

  it('omits fields a quick capture left empty', () => {
    const quick = toForumPost([findings[1]], { pack, characters });
    expect(quick).not.toContain('**Steps**');
    expect(quick).not.toContain('**Expected:**');
  });

  it('returns nothing rather than an empty shell when there is nothing to report', () => {
    expect(toForumPost([], { pack })).toBe('');
  });
});

describe('toDigest', () => {
  it('writes one line per finding for a chat paste', () => {
    expect(toDigest(findings)).toBe(
      '- [blocker] Skyborne flight form drops on zone edge (Zephras Isle)\n- [polish] Quest text calls the isle "Zephra"',
    );
  });
});
