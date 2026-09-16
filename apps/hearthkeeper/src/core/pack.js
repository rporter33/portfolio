// Content packs.
//
// A beta's facts change under you: a zone's level range shifts, a dungeon gets named, a phase
// date lands. So game data is never hardcoded into the UI — it arrives as a versioned pack,
// and the app can diff the pack it is holding against a newer one and show a tester exactly
// what moved. Findings keep the pack's `gameBuild` stamp, so a report from the opening build
// is never silently re-read as a report about a later one.

export const CONTENT_KINDS = ['zones', 'dungeons', 'raids'];

export function validatePack(pack) {
  const errors = [];
  if (!pack || typeof pack !== 'object') return { valid: false, errors: ['Pack is not an object.'] };
  if (!pack.packId) errors.push('Missing packId.');
  if (!Number.isFinite(pack.packVersion)) errors.push('Missing packVersion.');
  if (!pack.beta || !Array.isArray(pack.beta.phases) || pack.beta.phases.length === 0) {
    errors.push('Pack has no beta phases.');
  }
  for (const kind of CONTENT_KINDS) {
    if (pack[kind] && !Array.isArray(pack[kind])) errors.push(`${kind} must be an array.`);
  }
  return { valid: errors.length === 0, errors };
}

/** Every zone, dungeon and raid in one list, each tagged with the collection it came from. */
export function contentEntries(pack) {
  return CONTENT_KINDS.flatMap((kind) =>
    (pack?.[kind] ?? []).map((entry) => ({ ...entry, collection: kind })),
  );
}

export function contentById(pack, id) {
  return contentEntries(pack).find((entry) => entry.id === id) ?? null;
}

export function racesById(pack) {
  return new Map((pack?.races ?? []).map((race) => [race.id, race]));
}

export function isNewCombo(pack, raceId, className) {
  return (pack?.newCombos ?? []).some(
    (combo) => combo.raceId === raceId && combo.className === className,
  );
}

/** Race/class pairs a tester would specifically want covered: the six new ones plus the new race. */
export function priorityCombos(pack) {
  const races = racesById(pack);
  const fromNew = (pack?.newCombos ?? []).map((combo) => ({
    raceId: combo.raceId,
    raceName: races.get(combo.raceId)?.name ?? combo.raceId,
    className: combo.className,
    reason: 'new combination',
  }));
  const fromRace = (pack?.races ?? [])
    .filter((race) => race.isNew)
    .flatMap((race) =>
      (pack?.combos?.[race.id] ?? []).map((className) => ({
        raceId: race.id,
        raceName: race.name,
        className,
        reason: 'new race',
      })),
    );
  return [...fromRace, ...fromNew];
}

function indexById(list) {
  return new Map((list ?? []).filter((entry) => entry?.id).map((entry) => [entry.id, entry]));
}

function changedFields(before, after, fields) {
  return fields
    .filter((field) => JSON.stringify(before?.[field]) !== JSON.stringify(after?.[field]))
    .map((field) => ({ field, from: before?.[field] ?? null, to: after?.[field] ?? null }));
}

const TRACKED_FIELDS = ['name', 'minLevel', 'maxLevel', 'confidence', 'note', 'location', 'raidSize', 'levelCap', 'startsOn'];

/** What moved between two packs — the "what changed this build" view. */
export function diffPacks(before, after) {
  const sections = [];

  for (const kind of [...CONTENT_KINDS, 'races']) {
    const previous = indexById(before?.[kind]);
    const next = indexById(after?.[kind]);
    const added = [...next.values()].filter((entry) => !previous.has(entry.id));
    const removed = [...previous.values()].filter((entry) => !next.has(entry.id));
    const changed = [...next.values()]
      .filter((entry) => previous.has(entry.id))
      .map((entry) => ({ entry, fields: changedFields(previous.get(entry.id), entry, TRACKED_FIELDS) }))
      .filter((row) => row.fields.length > 0);
    if (added.length || removed.length || changed.length) sections.push({ kind, added, removed, changed });
  }

  const phasesBefore = indexById(before?.beta?.phases);
  const phasesAfter = indexById(after?.beta?.phases);
  const phaseChanges = [...phasesAfter.values()]
    .filter((phase) => phasesBefore.has(phase.id))
    .map((phase) => ({ entry: phase, fields: changedFields(phasesBefore.get(phase.id), phase, TRACKED_FIELDS) }))
    .filter((row) => row.fields.length > 0);
  const phasesAdded = [...phasesAfter.values()].filter((phase) => !phasesBefore.has(phase.id));
  if (phaseChanges.length || phasesAdded.length) {
    sections.push({ kind: 'phases', added: phasesAdded, removed: [], changed: phaseChanges });
  }

  const combosBefore = before?.combos ?? {};
  const combosAfter = after?.combos ?? {};
  const comboChanges = [];
  for (const raceId of new Set([...Object.keys(combosBefore), ...Object.keys(combosAfter)])) {
    const wasList = combosBefore[raceId] ?? [];
    const nowList = combosAfter[raceId] ?? [];
    const gained = nowList.filter((className) => !wasList.includes(className));
    const lost = wasList.filter((className) => !nowList.includes(className));
    if (gained.length || lost.length) comboChanges.push({ raceId, gained, lost });
  }

  const buildChanged = before?.gameBuild !== after?.gameBuild;
  const total =
    sections.reduce((sum, section) => sum + section.added.length + section.removed.length + section.changed.length, 0) +
    comboChanges.length;

  return { buildChanged, from: before?.gameBuild ?? null, to: after?.gameBuild ?? null, sections, comboChanges, total };
}
