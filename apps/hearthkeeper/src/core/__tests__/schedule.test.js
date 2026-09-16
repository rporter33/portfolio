import { describe, expect, it } from 'vitest';
import pack from '../../data/pack.2026-09-17.json';
import { maxBetaLevelCap, orderedPhases, phaseReaching, resolveSchedule } from '../schedule.js';

describe('resolveSchedule', () => {
  it('counts down before the beta opens', () => {
    const state = resolveSchedule(pack, '2026-09-16');
    expect(state.status).toBe('before');
    expect(state.daysUntilStart).toBe(1);
    expect(state.levelCap).toBeNull();
  });

  it('reports the level 20 cap on opening day', () => {
    const state = resolveSchedule(pack, '2026-09-17');
    expect(state.status).toBe('live');
    expect(state.phase.id).toBe('phase-1');
    expect(state.levelCap).toBe(20);
    expect(state.daysUntilNextPhase).toBe(14);
  });

  it('moves to the level 30 cap once phase 2 starts', () => {
    const state = resolveSchedule(pack, '2026-10-05');
    expect(state.phase.id).toBe('phase-2');
    expect(state.levelCap).toBe(30);
    expect(state.nextPhase).toBeNull();
    expect(state.daysRemaining).toBe(16);
  });

  it('closes out after the last day and counts toward launch', () => {
    const state = resolveSchedule(pack, '2026-10-22');
    expect(state.status).toBe('ended');
    expect(state.daysUntilLaunch).toBe(13);
  });

  it('is honest when it has no schedule to read', () => {
    expect(resolveSchedule({}, '2026-09-17').status).toBe('unknown');
    expect(resolveSchedule(pack, 'whenever').status).toBe('unknown');
  });

  it('orders phases by start day regardless of pack order', () => {
    const shuffled = { beta: { phases: [...pack.beta.phases].reverse() } };
    expect(orderedPhases(shuffled).map((phase) => phase.id)).toEqual(['phase-1', 'phase-2']);
  });
});

describe('beta reach', () => {
  it('knows the highest cap the beta will ever reach', () => {
    expect(maxBetaLevelCap(pack)).toBe(30);
  });

  it('names the first phase that can reach a level, or none', () => {
    expect(phaseReaching(pack, 18).id).toBe('phase-1');
    expect(phaseReaching(pack, 25).id).toBe('phase-2');
    expect(phaseReaching(pack, 45)).toBeNull();
  });
});
