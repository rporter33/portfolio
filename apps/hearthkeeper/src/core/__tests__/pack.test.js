import { describe, expect, it } from 'vitest';
import pack from '../../data/pack.2026-09-17.json';
import { contentById, contentEntries, diffPacks, isNewCombo, priorityCombos, validatePack } from '../pack.js';

describe('validatePack', () => {
  it('accepts the shipped pack', () => {
    expect(validatePack(pack).valid).toBe(true);
  });

  it('names what a broken pack is missing', () => {
    const result = validatePack({ packId: 'x' });
    expect(result.valid).toBe(false);
    expect(result.errors).toContain('Missing packVersion.');
    expect(result.errors).toContain('Pack has no beta phases.');
  });
});

describe('content', () => {
  it('flattens zones, dungeons and raids and remembers which is which', () => {
    const entries = contentEntries(pack);
    expect(entries.find((entry) => entry.id === 'zephras-isle').collection).toBe('zones');
    expect(entries.find((entry) => entry.id === 'hyjal-summit').collection).toBe('raids');
    expect(entries).toHaveLength(pack.zones.length + pack.dungeons.length + pack.raids.length);
  });

  it('looks an entry up by id', () => {
    expect(contentById(pack, 'the-riverglades').minLevel).toBe(30);
    expect(contentById(pack, 'nowhere')).toBeNull();
  });
});

describe('priority combos', () => {
  it('covers the new race and the six announced new pairings', () => {
    const combos = priorityCombos(pack);
    expect(combos.filter((combo) => combo.reason === 'new combination')).toHaveLength(6);
    expect(combos.some((combo) => combo.raceName.startsWith('Skyborne') && combo.className === 'Shaman')).toBe(true);
  });

  it('flags a pairing that is new in Forever', () => {
    expect(isNewCombo(pack, 'undead', 'Paladin')).toBe(true);
    expect(isNewCombo(pack, 'undead', 'Rogue')).toBe(false);
  });
});

describe('diffPacks', () => {
  it('reports nothing when a pack is unchanged', () => {
    expect(diffPacks(pack, pack).total).toBe(0);
  });

  it('catches a level range moving, a dungeon arriving and a class list growing', () => {
    const next = structuredClone(pack);
    next.gameBuild = 'beta-phase-2';
    next.zones.find((zone) => zone.id === 'the-riverglades').minLevel = 28;
    next.dungeons.push({ id: 'new-depths', name: 'The New Depths', kind: 'dungeon', confidence: 'announced' });
    next.combos['skyborne-elf-horde'] = ['Shaman', 'Hunter'];

    const diff = diffPacks(pack, next);
    expect(diff.buildChanged).toBe(true);
    const zones = diff.sections.find((section) => section.kind === 'zones');
    expect(zones.changed[0].fields).toEqual([{ field: 'minLevel', from: 30, to: 28 }]);
    expect(diff.sections.find((section) => section.kind === 'dungeons').added).toHaveLength(1);
    expect(diff.comboChanges).toEqual([{ raceId: 'skyborne-elf-horde', gained: ['Hunter'], lost: [] }]);
  });

  it('catches a phase date slipping', () => {
    const next = structuredClone(pack);
    next.beta.phases[1].startsOn = '2026-10-08';
    const phases = diffPacks(pack, next).sections.find((section) => section.kind === 'phases');
    expect(phases.changed[0].fields[0]).toEqual({ field: 'startsOn', from: '2026-10-01', to: '2026-10-08' });
  });
});
