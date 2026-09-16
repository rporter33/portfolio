import { useMemo, useState } from 'react';
import { FINDING_TYPES, SEVERITIES, STATUSES, filterFindings, findDuplicates, sortFindings } from '../core/journal.js';
import { contentEntries } from '../core/pack.js';
import { toDigest, toForumPost } from '../core/report.js';
import { Badge, Empty, Field, SectionTitle } from './parts.jsx';

const BLANK = {
  title: '',
  type: 'bug',
  severity: 'minor',
  contentId: '',
  level: '',
  characterId: '',
  steps: '',
  expected: '',
  actual: '',
  reproducible: 'unknown',
  tags: '',
};

const SEVERITY_TONE = { blocker: 'bad', major: 'warn', minor: 'neutral', polish: 'muted' };

export default function Journal({ pack, findings, characters, actions, day }) {
  const [draft, setDraft] = useState(BLANK);
  const [expanded, setExpanded] = useState(false);
  const [query, setQuery] = useState({ text: '', type: '', severity: '', status: '' });
  const [copied, setCopied] = useState(null);

  const entries = contentEntries(pack);
  const visible = useMemo(() => sortFindings(filterFindings(findings, query)), [findings, query]);
  const duplicates = draft.title.trim()
    ? findDuplicates(findings, { id: null, title: draft.title, contentId: draft.contentId || null })
    : [];

  function submit(event) {
    event.preventDefault();
    if (!draft.title.trim()) return;
    const entry = entries.find((item) => item.id === draft.contentId) ?? null;
    actions.addFinding({ ...draft, contentId: entry?.id ?? null, contentName: entry?.name ?? null });
    setDraft(BLANK);
    setExpanded(false);
  }

  async function copy(text, label) {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(label);
      setTimeout(() => setCopied(null), 2000);
    } catch {
      setCopied('clipboard blocked — select the text below instead');
    }
  }

  const report = toForumPost(visible, { pack, characters, day });

  return (
    <div className="stack">
      <section className="card">
        <SectionTitle aside="a title is enough — fill the rest later">Log a finding</SectionTitle>
        <form onSubmit={submit} className="stack">
          <Field label="What happened">
            <input
              value={draft.title}
              onChange={(event) => setDraft({ ...draft, title: event.target.value })}
              placeholder="Quest giver missing after phase change"
              maxLength={160}
              required
            />
          </Field>

          {duplicates.length > 0 ? (
            <p className="note note--warn">
              You already logged {duplicates.length === 1 ? 'this one' : `${duplicates.length} like this`} in the same
              place: “{duplicates[0].title}”.
            </p>
          ) : null}

          <div className="row row--wrap">
            <Field label="Type">
              <select value={draft.type} onChange={(event) => setDraft({ ...draft, type: event.target.value })}>
                {FINDING_TYPES.map((type) => (
                  <option key={type} value={type}>
                    {type}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Severity">
              <select value={draft.severity} onChange={(event) => setDraft({ ...draft, severity: event.target.value })}>
                {SEVERITIES.map((severity) => (
                  <option key={severity} value={severity}>
                    {severity}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Where">
              <select value={draft.contentId} onChange={(event) => setDraft({ ...draft, contentId: event.target.value })}>
                <option value="">—</option>
                {entries.map((entry) => (
                  <option key={entry.id} value={entry.id}>
                    {entry.name}
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
                placeholder="—"
              />
            </Field>
            <Field label="Character">
              <select
                value={draft.characterId}
                onChange={(event) => setDraft({ ...draft, characterId: event.target.value })}
              >
                <option value="">—</option>
                {characters.map((character) => (
                  <option key={character.id} value={character.id}>
                    {character.name}
                  </option>
                ))}
              </select>
            </Field>
          </div>

          {expanded ? (
            <div className="stack">
              <Field label="Steps" hint="One per line. They get renumbered in the export.">
                <textarea
                  rows={3}
                  value={draft.steps}
                  onChange={(event) => setDraft({ ...draft, steps: event.target.value })}
                />
              </Field>
              <div className="row row--wrap">
                <Field label="Expected">
                  <input value={draft.expected} onChange={(event) => setDraft({ ...draft, expected: event.target.value })} />
                </Field>
                <Field label="Actual">
                  <input value={draft.actual} onChange={(event) => setDraft({ ...draft, actual: event.target.value })} />
                </Field>
                <Field label="Reproducible">
                  <select
                    value={draft.reproducible}
                    onChange={(event) => setDraft({ ...draft, reproducible: event.target.value })}
                  >
                    {['unknown', 'always', 'sometimes', 'once'].map((option) => (
                      <option key={option} value={option}>
                        {option}
                      </option>
                    ))}
                  </select>
                </Field>
                <Field label="Tags" hint="comma separated">
                  <input value={draft.tags} onChange={(event) => setDraft({ ...draft, tags: event.target.value })} />
                </Field>
              </div>
            </div>
          ) : null}

          <div className="row">
            <button type="submit" className="button button--primary">
              Log it
            </button>
            <button type="button" className="button" onClick={() => setExpanded((value) => !value)}>
              {expanded ? 'Fewer fields' : 'More detail'}
            </button>
          </div>
        </form>
      </section>

      <section className="card">
        <SectionTitle aside={`${visible.length} of ${findings.length}`}>Journal</SectionTitle>
        <div className="row row--wrap filters">
          <input
            placeholder="Search"
            value={query.text}
            onChange={(event) => setQuery({ ...query, text: event.target.value })}
          />
          <select value={query.severity} onChange={(event) => setQuery({ ...query, severity: event.target.value })}>
            <option value="">any severity</option>
            {SEVERITIES.map((severity) => (
              <option key={severity} value={severity}>
                {severity}
              </option>
            ))}
          </select>
          <select value={query.type} onChange={(event) => setQuery({ ...query, type: event.target.value })}>
            <option value="">any type</option>
            {FINDING_TYPES.map((type) => (
              <option key={type} value={type}>
                {type}
              </option>
            ))}
          </select>
          <select value={query.status} onChange={(event) => setQuery({ ...query, status: event.target.value })}>
            <option value="">any status</option>
            {STATUSES.map((status) => (
              <option key={status} value={status}>
                {status}
              </option>
            ))}
          </select>
        </div>

        {visible.length === 0 ? (
          <Empty>{findings.length === 0 ? 'Nothing logged yet.' : 'No findings match that filter.'}</Empty>
        ) : (
          <ul className="list">
            {visible.map((finding) => (
              <li key={finding.id} className="finding">
                <div className="finding__head">
                  <span>
                    <Badge tone={SEVERITY_TONE[finding.severity] ?? 'neutral'}>{finding.severity}</Badge>{' '}
                    <Badge tone="muted">{finding.type}</Badge> <strong>{finding.title}</strong>
                  </span>
                  <span className="row">
                    <select
                      value={finding.status}
                      onChange={(event) => actions.editFinding(finding.id, { status: event.target.value })}
                      aria-label={`Status for ${finding.title}`}
                    >
                      {STATUSES.map((status) => (
                        <option key={status} value={status}>
                          {status}
                        </option>
                      ))}
                    </select>
                    <button type="button" className="link link--danger" onClick={() => actions.removeFinding(finding.id)}>
                      delete
                    </button>
                  </span>
                </div>
                <p className="finding__meta muted">
                  {[finding.contentName, finding.level ? `level ${finding.level}` : null, finding.gameBuild]
                    .filter(Boolean)
                    .join(' · ')}
                </p>
                {finding.actual ? <p className="finding__body">{finding.actual}</p> : null}
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="card">
        <SectionTitle aside="markdown, pastes into a forum post or a bug report">Export what is filtered</SectionTitle>
        <div className="row">
          <button type="button" className="button button--primary" disabled={!report} onClick={() => copy(report, 'report')}>
            Copy report
          </button>
          <button
            type="button"
            className="button"
            disabled={visible.length === 0}
            onClick={() => copy(toDigest(visible), 'digest')}
          >
            Copy one-line digest
          </button>
          {copied ? <span className="note">{copied === 'report' || copied === 'digest' ? 'copied' : copied}</span> : null}
        </div>
        {report ? <pre className="preview">{report}</pre> : <Empty>Nothing to export with these filters.</Empty>}
      </section>
    </div>
  );
}
