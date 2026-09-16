import { REACH } from '../core/coverage.js';
import { Badge, Confidence, Empty, SectionTitle } from './parts.jsx';

const REACH_LABEL = {
  [REACH.REACHABLE]: { tone: 'ok', text: 'reachable now' },
  [REACH.LATER_PHASE]: { tone: 'warn', text: 'later phase' },
  [REACH.BEYOND_BETA]: { tone: 'muted', text: 'not in this beta' },
  [REACH.UNKNOWN]: { tone: 'neutral', text: 'range unannounced' },
};

export default function Coverage({ coverage, levelCap }) {
  const bar = coverage.percent ?? 0;

  return (
    <div className="stack">
      <section className="card">
        <SectionTitle aside={levelCap ? `at the level ${levelCap} cap` : 'no live cap'}>Content coverage</SectionTitle>
        <div className="meter" role="img" aria-label={`${bar}% of reachable content has findings logged`}>
          <div className="meter__fill" style={{ width: `${bar}%` }} />
        </div>
        <p className="muted">
          {coverage.touchedCount} of {coverage.reachableCount} reachable entries have findings logged. Content the current
          cap cannot reach is listed but never counted against you.
        </p>

        <div className="table-wrap"><table className="table">
          <thead>
            <tr>
              <th>Content</th>
              <th>Levels</th>
              <th>Reach</th>
              <th>Findings</th>
            </tr>
          </thead>
          <tbody>
            {coverage.entries.map((entry) => {
              const label = REACH_LABEL[entry.reach];
              return (
                <tr key={entry.id} className={entry.reach === REACH.REACHABLE && !entry.touched ? 'row--todo' : ''}>
                  <td>
                    {entry.name} <Confidence level={entry.confidence} note={entry.note} />
                    <span className="muted"> · {entry.collection.slice(0, -1)}</span>
                    {entry.reachNote ? <p className="muted small">{entry.reachNote}</p> : null}
                  </td>
                  <td>{entry.minLevel ? `${entry.minLevel}–${entry.maxLevel ?? '?'}` : '—'}</td>
                  <td>
                    <Badge tone={label.tone}>{label.text}</Badge>
                  </td>
                  <td>
                    {entry.findingCount}
                    {entry.blockerCount ? <Badge tone="bad">{entry.blockerCount} blocker</Badge> : null}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table></div>
      </section>

      <section className="card">
        <SectionTitle aside={`${coverage.combos.playedCount} of ${coverage.combos.total} rolled`}>
          New race and class combinations
        </SectionTitle>
        {coverage.combos.rows.length === 0 ? (
          <Empty>This pack lists no new combinations.</Empty>
        ) : (
          <div className="table-wrap"><table className="table">
            <thead>
              <tr>
                <th>Pairing</th>
                <th>Why it matters</th>
                <th>Rolled</th>
                <th>Findings</th>
              </tr>
            </thead>
            <tbody>
              {coverage.combos.rows.map((row) => (
                <tr key={`${row.raceId}-${row.className}`} className={row.played ? '' : 'row--todo'}>
                  <td>
                    {row.raceName} {row.className}
                  </td>
                  <td className="muted">{row.reason}</td>
                  <td>{row.played ? <Badge tone="ok">to level {row.highestLevel}</Badge> : <Badge tone="muted">not yet</Badge>}</td>
                  <td>{row.findingCount}</td>
                </tr>
              ))}
            </tbody>
          </table></div>
        )}
      </section>
    </div>
  );
}
