// Export and import.
//
// The escape hatch that makes local-first honest: a tester's findings leave as a single JSON
// file they own. Imports accept anything this app ever wrote — the schema version is checked
// and migrated, never assumed — because a beta lasts five weeks and the app will change during
// it.

import { createFinding, validateFinding } from './journal.js';
import { createCharacter } from './roster.js';

export const SCHEMA_VERSION = 1;
export const STORAGE_KEY = 'hearthkeeper.state.v1';

export function emptyState(options = {}) {
  return {
    schema: SCHEMA_VERSION,
    findings: [],
    characters: [],
    packSnapshot: null,
    settings: { activePackId: options.activePackId ?? null },
  };
}

export function exportBackup(state, options = {}) {
  return {
    app: 'hearthkeeper',
    schema: SCHEMA_VERSION,
    exportedAt: options.now ?? new Date().toISOString(),
    findings: state?.findings ?? [],
    characters: state?.characters ?? [],
    settings: state?.settings ?? {},
    packSnapshot: state?.packSnapshot ?? null,
  };
}

function migrate(payload) {
  // Only one schema so far. Future migrations chain here, oldest first, so an import never
  // needs to know which version it came from.
  return payload;
}

/**
 * Import a backup. Returns the state plus a report of what was skipped — a partially valid
 * file should restore the valid part, not fail whole.
 */
export function importBackup(payload, options = {}) {
  const parsed = typeof payload === 'string' ? safeParse(payload) : payload;
  if (!parsed || typeof parsed !== 'object') {
    return { ok: false, errors: ['That file is not valid JSON.'], state: null };
  }
  if (parsed.app && parsed.app !== 'hearthkeeper') {
    return { ok: false, errors: [`That backup came from "${parsed.app}", not Hearthkeeper.`], state: null };
  }
  if (Number.isFinite(parsed.schema) && parsed.schema > SCHEMA_VERSION) {
    return {
      ok: false,
      errors: [`That backup is schema ${parsed.schema}; this build reads up to ${SCHEMA_VERSION}. Update the app first.`],
      state: null,
    };
  }

  const data = migrate(parsed);
  const skipped = [];

  const findings = (Array.isArray(data.findings) ? data.findings : [])
    .map((finding) => createFinding(finding, { id: finding?.id, now: finding?.createdAt }))
    .filter((finding) => {
      const { valid, errors } = validateFinding(finding);
      if (!valid) skipped.push(`Finding "${finding.title || '(untitled)'}": ${errors.join(' ')}`);
      return valid;
    });

  const characters = (Array.isArray(data.characters) ? data.characters : []).map((character) =>
    createCharacter(character, { id: character?.id, now: character?.createdAt }),
  );

  const existing = options.mergeInto;
  const state = existing
    ? {
        ...existing,
        findings: mergeById(existing.findings, findings),
        characters: mergeById(existing.characters, characters),
        settings: { ...existing.settings, ...(data.settings ?? {}) },
        packSnapshot: data.packSnapshot ?? existing.packSnapshot ?? null,
      }
    : {
        schema: SCHEMA_VERSION,
        findings,
        characters,
        settings: data.settings ?? {},
        packSnapshot: data.packSnapshot ?? null,
      };

  return { ok: true, errors: [], skipped, state, imported: { findings: findings.length, characters: characters.length } };
}

function mergeById(existing = [], incoming = []) {
  const byId = new Map(existing.map((entry) => [entry.id, entry]));
  for (const entry of incoming) {
    const current = byId.get(entry.id);
    // Last edit wins, so re-importing an older backup never rolls a finding backwards.
    if (!current || String(entry.updatedAt ?? '') > String(current.updatedAt ?? '')) byId.set(entry.id, entry);
  }
  return [...byId.values()];
}

function safeParse(text) {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

export function backupFilename(day) {
  return `hearthkeeper-${day ?? new Date().toISOString().slice(0, 10)}.json`;
}
