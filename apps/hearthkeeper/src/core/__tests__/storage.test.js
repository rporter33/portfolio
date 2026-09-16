import { describe, expect, it } from 'vitest';
import { memoryStore, readJSON, resolveStore, writeJSON } from '../storage.js';

function fakeLocalStorage({ throwOnSet = false } = {}) {
  const map = new Map();
  return {
    getItem: (key) => (map.has(key) ? map.get(key) : null),
    setItem: (key, value) => {
      if (throwOnSet) throw new DOMException('QuotaExceededError');
      map.set(key, value);
    },
    removeItem: (key) => map.delete(key),
  };
}

describe('resolveStore', () => {
  it('prefers a host-provided store', () => {
    const store = resolveStore({ hearthkeeperStore: { get: () => null, set: () => true, remove: () => {} } });
    expect(store.kind).toBe('host');
  });

  it('falls back to localStorage, then to memory', () => {
    expect(resolveStore({ localStorage: fakeLocalStorage() }).kind).toBe('localStorage');
    expect(resolveStore({}).kind).toBe('memory');
  });
});

describe('json helpers', () => {
  it('round-trips a value', () => {
    const store = memoryStore();
    expect(writeJSON(store, 'k', { a: 1 })).toBe(true);
    expect(readJSON(store, 'k')).toEqual({ a: 1 });
  });

  it('returns the fallback for a missing or corrupt value instead of throwing', () => {
    const store = memoryStore({ broken: '{not json' });
    expect(readJSON(store, 'absent', 'fallback')).toBe('fallback');
    expect(readJSON(store, 'broken', 'fallback')).toBe('fallback');
  });

  it('reports a quota refusal rather than pretending the write landed', () => {
    const store = resolveStore({ localStorage: fakeLocalStorage({ throwOnSet: true }) });
    expect(writeJSON(store, 'k', { a: 1 })).toBe(false);
  });

  it('survives a localStorage that throws on read', () => {
    const hostile = { getItem: () => { throw new Error('blocked'); }, setItem: () => {}, removeItem: () => {} };
    expect(readJSON(resolveStore({ localStorage: hostile }), 'k', null)).toBeNull();
  });
});
