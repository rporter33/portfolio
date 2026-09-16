// Storage adapter.
//
// Same position as the rest of my local-first work: the browser is the database. No accounts,
// no server, nothing to breach. The cost is no cross-device sync, and the export file in
// backup.js is how that cost gets paid rather than hidden.
//
// The indirection is one layer deep on purpose — swapping localStorage for IndexedDB, or for a
// host-provided per-user store, is a change to this file and nothing else.

export function memoryStore(seed = {}) {
  const map = new Map(Object.entries(seed));
  return {
    kind: 'memory',
    get: (key) => (map.has(key) ? map.get(key) : null),
    set: (key, value) => void map.set(key, value),
    remove: (key) => void map.delete(key),
  };
}

function localStorageStore(storage) {
  return {
    kind: 'localStorage',
    get(key) {
      try {
        return storage.getItem(key);
      } catch {
        return null;
      }
    },
    set(key, value) {
      try {
        storage.setItem(key, value);
        return true;
      } catch {
        // Quota or a private-mode refusal. The app keeps working on in-memory state; the
        // caller surfaces this so a tester learns before they lose a session of findings.
        return false;
      }
    },
    remove(key) {
      try {
        storage.removeItem(key);
      } catch {
        /* nothing useful to do */
      }
    },
  };
}

export function resolveStore(scope = globalThis) {
  if (scope?.hearthkeeperStore) return { kind: 'host', ...scope.hearthkeeperStore };
  if (scope?.localStorage) return localStorageStore(scope.localStorage);
  return memoryStore();
}

export function readJSON(store, key, fallback = null) {
  const raw = store.get(key);
  if (raw == null) return fallback;
  if (typeof raw === 'object') return raw;
  try {
    return JSON.parse(raw);
  } catch {
    return fallback;
  }
}

export function writeJSON(store, key, value) {
  return store.set(key, JSON.stringify(value)) !== false;
}
