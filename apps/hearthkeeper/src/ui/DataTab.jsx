import { useMemo, useRef, useState } from 'react';
import { backupFilename } from '../core/backup.js';
import { formatDay } from '../core/dates.js';
import { diffPacks } from '../core/pack.js';
import { Badge, Confidence, Empty, SectionTitle, confidenceHelp } from './parts.jsx';

function DiffSection({ section }) {
  return (
    <div className="stack stack--tight">
      <h4 className="diff__kind">{section.kind}</h4>
      {section.added.map((entry) => (
        <p key={`a-${entry.id}`} className="diff__line">
          <Badge tone="ok">added</Badge> {entry.name ?? entry.id}
        </p>
      ))}
      {section.removed.map((entry) => (
        <p key={`r-${entry.id}`} className="diff__line">
          <Badge tone="bad">removed</Badge> {entry.name ?? entry.id}
        </p>
      ))}
      {section.changed.map((row) => (
        <p key={`c-${row.entry.id}`} className="diff__line">
          <Badge tone="warn">changed</Badge> {row.entry.name ?? row.entry.id}
          {row.fields.map((field) => (
            <span key={field.field} className="muted">
              {' '}
              · {field.field}: {String(field.from)} → {String(field.to)}
            </span>
          ))}
        </p>
      ))}
    </div>
  );
}

export default function DataTab({ pack, snapshot, state, backup, actions, storageHealthy }) {
  const [message, setMessage] = useState(null);
  const fileInput = useRef(null);
  const diff = useMemo(() => (snapshot ? diffPacks(snapshot, pack) : null), [snapshot, pack]);

  function download() {
    const blob = new Blob([JSON.stringify(backup(), null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = backupFilename();
    link.click();
    URL.revokeObjectURL(url);
  }

  async function restore(event, merge) {
    const file = event.target.files?.[0];
    if (!file) return;
    const text = await file.text();
    const result = actions.restore(text, { merge });
    setMessage(
      result.ok
        ? `Restored ${result.imported.findings} findings and ${result.imported.characters} characters.${
            result.skipped.length ? ` Skipped ${result.skipped.length}.` : ''
          }`
        : result.errors.join(' '),
    );
    event.target.value = '';
  }

  const provenanceRows = [
    ...pack.zones.map((entry) => ({ ...entry, group: 'zone' })),
    ...pack.dungeons.map((entry) => ({ ...entry, group: 'dungeon' })),
    ...pack.raids.map((entry) => ({ ...entry, group: 'raid' })),
  ];

  return (
    <div className="stack">
      <section className="card">
        <SectionTitle aside={`pack v${pack.packVersion}`}>{pack.label}</SectionTitle>
        <p className="muted">
          Build stamp <code>{pack.gameBuild}</code> · compiled {formatDay(pack.compiledOn)}
        </p>
        <p className="note">{pack.notice}</p>
        {pack.partialData?.length ? (
          <>
            <h4>Known gaps</h4>
            <ul className="list list--plain">
              {pack.partialData.map((gap) => (
                <li key={gap} className="muted">
                  {gap}
                </li>
              ))}
            </ul>
          </>
        ) : null}
      </section>

      {diff && diff.total > 0 ? (
        <section className="card">
          <SectionTitle aside={`${diff.total} change${diff.total === 1 ? '' : 's'}`}>
            What changed since your last pack
          </SectionTitle>
          <p className="muted">
            {diff.from ?? 'unknown'} → {diff.to ?? 'unknown'}
          </p>
          {diff.sections.map((section) => (
            <DiffSection key={section.kind} section={section} />
          ))}
          {diff.comboChanges.map((change) => (
            <p key={change.raceId} className="diff__line">
              <Badge tone="warn">combos</Badge> {change.raceId}
              {change.gained.length ? <span className="muted"> · gained {change.gained.join(', ')}</span> : null}
              {change.lost.length ? <span className="muted"> · lost {change.lost.join(', ')}</span> : null}
            </p>
          ))}
          <button type="button" className="button button--primary" onClick={() => actions.adoptPack(pack)}>
            Mark as seen
          </button>
        </section>
      ) : null}

      <section className="card">
        <SectionTitle aside="every row says where it came from">Provenance</SectionTitle>
        <div className="table-wrap"><table className="table">
          <thead>
            <tr>
              <th>Entry</th>
              <th>Kind</th>
              <th>Confidence</th>
            </tr>
          </thead>
          <tbody>
            {provenanceRows.map((entry) => (
              <tr key={entry.id}>
                <td>
                  {entry.name}
                  {entry.note ? <p className="muted small">{entry.note}</p> : null}
                </td>
                <td className="muted">{entry.group}</td>
                <td>
                  <Confidence level={entry.confidence} />
                  <span className="muted small"> {confidenceHelp(entry.confidence)}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table></div>
      </section>

      <section className="card">
        <SectionTitle aside="your data is a file you own">Backup</SectionTitle>
        {!storageHealthy ? (
          <p className="note note--warn">
            This browser refused to save to local storage — private mode or a full quota. Everything still works this
            session, but export before you close the tab.
          </p>
        ) : null}
        <p className="muted">
          {state.findings.length} findings and {state.characters.length} characters live in this browser. Nothing is sent
          anywhere; there is no account and no server.
        </p>
        <div className="row row--wrap">
          <button type="button" className="button button--primary" onClick={download}>
            Export JSON
          </button>
          <button type="button" className="button" onClick={() => fileInput.current?.click()}>
            Import (merge)
          </button>
          <input
            ref={fileInput}
            type="file"
            accept="application/json"
            hidden
            onChange={(event) => restore(event, true)}
          />
          <button
            type="button"
            className="button button--danger"
            onClick={() => {
              if (window.confirm('Delete every finding and character in this browser? Export first if you want them.')) {
                actions.clearAll();
                setMessage('Cleared.');
              }
            }}
          >
            Clear everything
          </button>
        </div>
        {message ? <p className="note">{message}</p> : null}
        {state.findings.length === 0 && state.characters.length === 0 ? <Empty>Nothing stored yet.</Empty> : null}
      </section>
    </div>
  );
}
