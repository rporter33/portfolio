import { describe, expect, it } from 'vitest';
import { SCHEMA_VERSION, backupFilename, emptyState, exportBackup, importBackup } from '../backup.js';
import { createFinding } from '../journal.js';
import { createCharacter } from '../roster.js';

const state = {
  ...emptyState(),
  findings: [createFinding({ title: 'Wind wall clips', severity: 'major' }, { id: 'f1', now: '2026-09-17T10:00:00Z' })],
  characters: [createCharacter({ name: 'Aelyn', raceId: 'skyborne-elf-horde', className: 'Shaman', level: 9 }, { id: 'c1' })],
};

describe('round trip', () => {
  it('restores an export unchanged', () => {
    const payload = JSON.stringify(exportBackup(state, { now: '2026-09-18T00:00:00Z' }));
    const result = importBackup(payload);
    expect(result.ok).toBe(true);
    expect(result.state.findings[0].title).toBe('Wind wall clips');
    expect(result.state.characters[0].name).toBe('Aelyn');
    expect(result.imported).toEqual({ findings: 1, characters: 1 });
  });

  it('names the file by day', () => {
    expect(backupFilename('2026-09-18')).toBe('hearthkeeper-2026-09-18.json');
  });
});

describe('refusals', () => {
  it('rejects a file that is not JSON', () => {
    expect(importBackup('{nope').ok).toBe(false);
  });

  it('rejects another app’s backup', () => {
    expect(importBackup({ app: 'something-else', findings: [] }).errors[0]).toContain('something-else');
  });

  it('refuses a newer schema rather than silently dropping fields', () => {
    const result = importBackup({ app: 'hearthkeeper', schema: SCHEMA_VERSION + 1, findings: [] });
    expect(result.ok).toBe(false);
    expect(result.errors[0]).toContain('Update the app first');
  });
});

describe('partial files', () => {
  it('imports the valid entries and reports the ones it skipped', () => {
    const result = importBackup({
      app: 'hearthkeeper',
      schema: 1,
      findings: [{ id: 'f1', title: 'Good one' }, { id: 'f2', title: '' }],
    });
    expect(result.ok).toBe(true);
    expect(result.state.findings).toHaveLength(1);
    expect(result.skipped).toHaveLength(1);
  });

  it('tolerates a file with no arrays at all', () => {
    const result = importBackup({ app: 'hearthkeeper', schema: 1 });
    expect(result.ok).toBe(true);
    expect(result.state.findings).toEqual([]);
  });
});

describe('merge', () => {
  const existing = {
    ...emptyState(),
    findings: [createFinding({ title: 'Edited later', severity: 'blocker' }, { id: 'f1', now: '2026-09-20T00:00:00Z' })],
  };

  it('keeps the newer edit when an older backup is imported over it', () => {
    const older = exportBackup(state);
    const result = importBackup(older, { mergeInto: existing });
    expect(result.state.findings).toHaveLength(1);
    expect(result.state.findings[0].title).toBe('Edited later');
  });

  it('adds entries the existing state does not have', () => {
    const incoming = exportBackup({
      ...state,
      findings: [createFinding({ title: 'From the laptop' }, { id: 'f9', now: '2026-09-19T00:00:00Z' })],
    });
    const result = importBackup(incoming, { mergeInto: existing });
    expect(result.state.findings.map((finding) => finding.id).sort()).toEqual(['f1', 'f9']);
  });
});
