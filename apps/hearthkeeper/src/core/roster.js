// Beta characters.
//
// Validation here has an unusual job: it has to distinguish "that race cannot be that class"
// from "nobody has announced whether that race can be that class". The Skyborne Elves are the
// live case — one class confirmed per faction and the rest unannounced — so an unknown pairing
// is a warning, never an error, and the pack says which races have incomplete lists.

import { isNewCombo, racesById } from './pack.js';
import { numberOr } from './values.js';

export function createCharacter(input = {}, options = {}) {
  return {
    id: options.id ?? `c_${Math.random().toString(36).slice(2, 10)}`,
    createdAt: options.now ?? new Date().toISOString(),
    name: String(input.name ?? '').trim(),
    raceId: input.raceId ?? null,
    className: input.className ?? null,
    level: numberOr(input.level, 1),
    notes: String(input.notes ?? '').trim(),
    build: input.build ?? { trees: {} },
  };
}

function raceHasPartialCombos(pack, race) {
  if (!race?.isNew) return false;
  const known = pack?.combos?.[race.id] ?? [];
  return known.length < (pack?.classes?.length ?? 9);
}

export function validateCharacter(character, pack, options = {}) {
  const errors = [];
  const warnings = [];
  const races = racesById(pack);
  const race = races.get(character?.raceId) ?? null;

  if (!character?.name) errors.push('Character needs a name.');
  if (!race) errors.push('Pick a race.');
  if (!character?.className) errors.push('Pick a class.');
  else if (!(pack?.classes ?? []).includes(character.className)) errors.push(`Unknown class: ${character.className}.`);

  if (!Number.isFinite(character?.level) || character.level < 1) errors.push('Level must be 1 or higher.');

  if (race && character?.className && (pack?.classes ?? []).includes(character.className)) {
    const allowed = pack?.combos?.[race.id] ?? [];
    if (!allowed.includes(character.className)) {
      if (raceHasPartialCombos(pack, race)) {
        warnings.push(`${race.name} ${character.className} is not in the announced class list — that list is incomplete, so this may still be valid in game.`);
      } else {
        errors.push(`${race.name} cannot be a ${character.className}.`);
      }
    }
  }

  const levelCap = options.levelCap ?? null;
  if (Number.isFinite(levelCap) && Number.isFinite(character?.level) && character.level > levelCap) {
    warnings.push(`Level ${character.level} is above the current beta cap of ${levelCap}.`);
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
    faction: race?.faction ?? null,
    isNewCombo: race ? isNewCombo(pack, race.id, character?.className) : false,
    isNewRace: Boolean(race?.isNew),
  };
}
