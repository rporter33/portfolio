import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { STORAGE_KEY, emptyState, exportBackup, importBackup } from './core/backup.js';
import { createFinding, updateFinding as reviseFinding } from './core/journal.js';
import { createCharacter } from './core/roster.js';
import { readJSON, resolveStore, writeJSON } from './core/storage.js';

/**
 * One hook holds the whole app's state. Everything it does is a pure function from core/ plus
 * a write to the storage adapter, which is what keeps the logic testable without React.
 */
export function useAppState(pack) {
  const store = useRef(null);
  if (store.current === null) store.current = resolveStore();

  const [state, setState] = useState(() => {
    const loaded = readJSON(store.current, STORAGE_KEY, null);
    if (!loaded) return { ...emptyState({ activePackId: pack.packId }), packSnapshot: pack };
    const result = importBackup(loaded);
    return result.ok ? result.state : { ...emptyState({ activePackId: pack.packId }), packSnapshot: pack };
  });

  const [storageHealthy, setStorageHealthy] = useState(true);

  useEffect(() => {
    setStorageHealthy(writeJSON(store.current, STORAGE_KEY, state));
  }, [state]);

  const actions = useMemo(
    () => ({
      addFinding: (input) =>
        setState((current) => ({
          ...current,
          findings: [createFinding(input, { gameBuild: pack.gameBuild }), ...current.findings],
        })),
      editFinding: (id, changes) =>
        setState((current) => ({
          ...current,
          findings: current.findings.map((finding) => (finding.id === id ? reviseFinding(finding, changes) : finding)),
        })),
      removeFinding: (id) =>
        setState((current) => ({ ...current, findings: current.findings.filter((finding) => finding.id !== id) })),
      addCharacter: (input) =>
        setState((current) => ({ ...current, characters: [...current.characters, createCharacter(input)] })),
      editCharacter: (id, changes) =>
        setState((current) => ({
          ...current,
          characters: current.characters.map((character) =>
            character.id === id ? { ...character, ...changes } : character,
          ),
        })),
      removeCharacter: (id) =>
        setState((current) => ({
          ...current,
          characters: current.characters.filter((character) => character.id !== id),
          findings: current.findings.map((finding) =>
            finding.characterId === id ? { ...finding, characterId: null } : finding,
          ),
        })),
      adoptPack: (nextPack) => setState((current) => ({ ...current, packSnapshot: nextPack })),
      restore: (payload, { merge }) => {
        const result = importBackup(payload, merge ? { mergeInto: state } : {});
        if (result.ok) setState(result.state);
        return result;
      },
      clearAll: () => setState({ ...emptyState({ activePackId: pack.packId }), packSnapshot: pack }),
    }),
    [pack, state],
  );

  const backup = useCallback(() => exportBackup(state), [state]);

  return { state, actions, backup, storageHealthy };
}
