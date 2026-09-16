import { useState } from 'react';
import { createCharacter, validateCharacter } from '../core/roster.js';
import { talentPointsAtLevel, validateBuild } from '../core/talents.js';
import { Badge, Empty, Field, SectionTitle } from './parts.jsx';

const BLANK = { name: '', raceId: '', className: '', level: 1, notes: '' };

function BuildEditor({ character, pack, onChange }) {
  const trees = pack.talents.trees?.[character.className] ?? [];
  const build = character.build ?? { trees: {} };
  const result = validateBuild(build, character.level, pack.talents);
  if (trees.length === 0) return null;

  function setTree(tree, value) {
    const points = Math.max(0, Number(value) || 0);
    onChange({ ...build, trees: { ...build.trees, [tree]: points } });
  }

  return (
    <div className="build">
      <div className="row row--wrap">
        {trees.map((tree) => {
          const points = build.trees?.[tree] ?? 0;
          const row = result.trees.find((item) => item.tree === tree);
          return (
            <Field key={tree} label={tree} hint={row?.nextMilestone ? `next tier at ${row.nextMilestone}` : 'top tier reached'}>
              <input type="number" min="0" value={points} onChange={(event) => setTree(tree, event.target.value)} />
            </Field>
          );
        })}
      </div>
      <p className={`note ${result.valid ? '' : 'note--warn'}`}>
        {result.spent} of {result.available} points spent at level {character.level}
        {result.valid ? '' : ` — ${result.errors.join(' ')}`}
      </p>
    </div>
  );
}

export default function Roster({ pack, characters, actions, levelCap }) {
  const [draft, setDraft] = useState(BLANK);
  const preview = createCharacter(draft, { id: 'draft' });
  const check = validateCharacter(preview, pack, { levelCap });
  const classesFor = (raceId) => pack.combos?.[raceId] ?? pack.classes;

  function submit(event) {
    event.preventDefault();
    if (!check.valid) return;
    actions.addCharacter(draft);
    setDraft(BLANK);
  }

  return (
    <div className="stack">
      <section className="card">
        <SectionTitle>Add a character</SectionTitle>
        <form onSubmit={submit} className="stack">
          <div className="row row--wrap">
            <Field label="Name">
              <input value={draft.name} onChange={(event) => setDraft({ ...draft, name: event.target.value })} required />
            </Field>
            <Field label="Race">
              <select
                value={draft.raceId}
                onChange={(event) => setDraft({ ...draft, raceId: event.target.value, className: '' })}
              >
                <option value="">—</option>
                {pack.races.map((race) => (
                  <option key={race.id} value={race.id}>
                    {race.name}
                    {race.isNew ? ' ★' : ''}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Class" hint={draft.raceId ? 'announced options for this race' : 'pick a race first'}>
              <select value={draft.className} onChange={(event) => setDraft({ ...draft, className: event.target.value })}>
                <option value="">—</option>
                {(draft.raceId ? classesFor(draft.raceId) : []).map((className) => (
                  <option key={className} value={className}>
                    {className}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Level">
              <input
                type="number"
                min="1"
                value={draft.level}
                onChange={(event) => setDraft({ ...draft, level: event.target.value })}
              />
            </Field>
          </div>

          {check.errors.map((error) => (
            <p key={error} className="note note--warn">
              {error}
            </p>
          ))}
          {check.warnings.map((warning) => (
            <p key={warning} className="note">
              {warning}
            </p>
          ))}
          {check.isNewCombo ? <p className="note note--good">New in Forever — worth testing deliberately.</p> : null}

          <div className="row">
            <button type="submit" className="button button--primary" disabled={!check.valid}>
              Add
            </button>
          </div>
        </form>
      </section>

      <section className="card">
        <SectionTitle aside={`${characters.length} on the roster`}>Beta characters</SectionTitle>
        {characters.length === 0 ? (
          <Empty>No characters yet. The coverage view uses these to work out which new pairings nobody has rolled.</Empty>
        ) : (
          <ul className="list">
            {characters.map((character) => {
              const state = validateCharacter(character, pack, { levelCap });
              const race = pack.races.find((entry) => entry.id === character.raceId);
              return (
                <li key={character.id} className="character">
                  <div className="finding__head">
                    <span>
                      <strong>{character.name}</strong>{' '}
                      <span className="muted">
                        {race?.name} {character.className} · level {character.level}
                      </span>{' '}
                      {state.faction ? <Badge tone={state.faction === 'Horde' ? 'bad' : 'info'}>{state.faction}</Badge> : null}{' '}
                      {state.isNewCombo ? <Badge tone="ok">new combo</Badge> : null}
                      {state.isNewRace ? <Badge tone="ok">new race</Badge> : null}
                    </span>
                    <span className="row">
                      <input
                        type="number"
                        min="1"
                        value={character.level}
                        aria-label={`Level for ${character.name}`}
                        onChange={(event) =>
                          actions.editCharacter(character.id, { level: Math.max(1, Number(event.target.value) || 1) })
                        }
                      />
                      <button type="button" className="link link--danger" onClick={() => actions.removeCharacter(character.id)}>
                        delete
                      </button>
                    </span>
                  </div>
                  {state.warnings.map((warning) => (
                    <p key={warning} className="note">
                      {warning}
                    </p>
                  ))}
                  <p className="muted">
                    {talentPointsAtLevel(character.level, pack.talents)} talent points available
                  </p>
                  <BuildEditor
                    character={character}
                    pack={pack}
                    onChange={(build) => actions.editCharacter(character.id, { build })}
                  />
                </li>
              );
            })}
          </ul>
        )}
      </section>
    </div>
  );
}
