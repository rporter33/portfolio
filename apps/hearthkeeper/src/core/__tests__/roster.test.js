import { describe, expect, it } from 'vitest';
import pack from '../../data/pack.2026-09-17.json';
import { createCharacter, validateCharacter } from '../roster.js';

const character = (input) => createCharacter(input, { id: 'c1', now: '2026-09-17T10:00:00Z' });

describe('validateCharacter', () => {
  it('accepts a classic pairing and derives the faction', () => {
    const result = validateCharacter(character({ name: 'Bramm', raceId: 'dwarf', className: 'Paladin', level: 14 }), pack);
    expect(result.valid).toBe(true);
    expect(result.faction).toBe('Alliance');
    expect(result.isNewCombo).toBe(false);
  });

  it('flags one of the six new pairings as new rather than wrong', () => {
    const result = validateCharacter(character({ name: 'Sarkoth', raceId: 'undead', className: 'Paladin', level: 8 }), pack);
    expect(result.valid).toBe(true);
    expect(result.isNewCombo).toBe(true);
  });

  it('rejects a pairing the pack rules out', () => {
    const result = validateCharacter(character({ name: 'Nope', raceId: 'tauren', className: 'Mage', level: 5 }), pack);
    expect(result.valid).toBe(false);
    expect(result.errors[0]).toContain('cannot be a Mage');
  });

  it('warns instead of erroring where the announced class list is admittedly incomplete', () => {
    const result = validateCharacter(character({ name: 'Aelyn', raceId: 'skyborne-elf-horde', className: 'Hunter', level: 6 }), pack);
    expect(result.valid).toBe(true);
    expect(result.warnings[0]).toContain('incomplete');
    expect(result.isNewRace).toBe(true);
  });

  it('warns about a level above the live cap without blocking it', () => {
    const result = validateCharacter(
      character({ name: 'Tall', raceId: 'orc', className: 'Shaman', level: 26 }),
      pack,
      { levelCap: 20 },
    );
    expect(result.valid).toBe(true);
    expect(result.warnings[0]).toContain('above the current beta cap');
  });

  it('collects every missing required field at once', () => {
    const result = validateCharacter(character({ name: '', raceId: null, className: null, level: 0 }), pack);
    expect(result.errors).toHaveLength(4);
  });
});

describe('character level defaults', () => {
  it('defaults a blank level to 1 rather than 0', () => {
    expect(createCharacter({ name: 'New', raceId: 'orc', className: 'Shaman', level: '' }).level).toBe(1);
    expect(createCharacter({ name: 'New', raceId: 'orc', className: 'Shaman' }).level).toBe(1);
  });
});
