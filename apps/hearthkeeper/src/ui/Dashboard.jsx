import { formatDay } from '../core/dates.js';
import { sortFindings, summarize } from '../core/journal.js';
import { suggestNext } from '../core/coverage.js';
import { milestoneSchedule } from '../core/talents.js';
import { Badge, Confidence, Empty, SectionTitle } from './parts.jsx';

function PhaseCard({ schedule, pack }) {
  if (schedule.status === 'before') {
    return (
      <div className="card card--hero">
        <p className="hero__kicker">Beta opens in</p>
        <p className="hero__number">{schedule.daysUntilStart} {schedule.daysUntilStart === 1 ? 'day' : 'days'}</p>
        <p className="hero__detail">
          {formatDay(schedule.startsOn)} → {formatDay(schedule.endsOn)} · launch {formatDay(pack.beta.launchesOn)}
        </p>
      </div>
    );
  }

  if (schedule.status === 'ended') {
    return (
      <div className="card card--hero">
        <p className="hero__kicker">Beta closed {formatDay(schedule.endsOn)}</p>
        <p className="hero__number">{schedule.daysUntilLaunch} days to launch</p>
        <p className="hero__detail">Level cap at launch: {pack.beta.launchLevelCap}</p>
      </div>
    );
  }

  if (schedule.status === 'unknown') {
    return (
      <div className="card card--hero">
        <p className="hero__kicker">No schedule in the loaded pack</p>
        <p className="hero__detail">Load a content pack on the Data tab.</p>
      </div>
    );
  }

  return (
    <div className="card card--hero">
      <p className="hero__kicker">
        {schedule.phase.name} · level cap <Confidence level={schedule.phase.confidence} note={schedule.phase.note} />
      </p>
      <p className="hero__number">{schedule.levelCap}</p>
      <p className="hero__detail">
        {schedule.daysRemaining} days of beta left
        {schedule.nextPhase
          ? ` · cap rises to ${schedule.nextPhase.levelCap} in ${schedule.daysUntilNextPhase} days`
          : ' · this is the final phase'}
      </p>
    </div>
  );
}

export default function Dashboard({ pack, schedule, coverage, findings, onGoTo }) {
  const counts = summarize(findings);
  const recent = sortFindings(findings).slice(0, 5);
  const milestones = milestoneSchedule(pack);
  const suggestions = suggestNext(coverage, 4);
  const openBlockers = findings.filter((finding) => finding.severity === 'blocker' && finding.status === 'open');

  return (
    <div className="stack">
      <PhaseCard schedule={schedule} pack={pack} />

      <div className="grid grid--3">
        <div className="card stat">
          <p className="stat__number">{counts.total}</p>
          <p className="stat__label">findings logged</p>
        </div>
        <div className="card stat">
          <p className="stat__number">{openBlockers.length}</p>
          <p className="stat__label">open blockers</p>
        </div>
        <div className="card stat">
          <p className="stat__number">{coverage.percent === null ? '—' : `${coverage.percent}%`}</p>
          <p className="stat__label">
            {coverage.reachableCount === 0
              ? 'nothing is reachable until a phase is live'
              : `of reachable content touched (${coverage.touchedCount}/${coverage.reachableCount})`}
          </p>
        </div>
      </div>

      <section className="card">
        <SectionTitle aside="what this phase can actually reach">Next</SectionTitle>
        {suggestions.length === 0 ? (
          <Empty>Everything the current cap can reach has findings against it. Go deeper, or wait for the next phase.</Empty>
        ) : (
          <ul className="list">
            {suggestions.map((suggestion) => (
              <li key={suggestion.id} className="list__row">
                <span>
                  <strong>{suggestion.label}</strong>
                  <span className="muted"> — {suggestion.detail}</span>
                </span>
                <button type="button" className="link" onClick={() => onGoTo(suggestion.kind === 'combo' ? 'roster' : 'coverage')}>
                  {suggestion.kind === 'combo' ? 'roll one' : 'open'}
                </button>
              </li>
            ))}
          </ul>
        )}
      </section>

      <section className="card">
        <SectionTitle aside={pack.talents.note ? 'per-talent data intentionally absent' : null}>
          Talent tiers, against the beta caps
        </SectionTitle>
        <div className="table-wrap"><table className="table">
          <thead>
            <tr>
              <th>Tier</th>
              <th>Needs level</th>
              <th>Testable</th>
            </tr>
          </thead>
          <tbody>
            {milestones.map((milestone) => (
              <tr key={milestone.points}>
                <td>
                  {milestone.points} points <Confidence level={milestone.confidence} note={milestone.note} />
                </td>
                <td>{milestone.requiredLevel}</td>
                <td>
                  {milestone.testableInBeta ? (
                    <Badge tone="ok">{milestone.phase.name}</Badge>
                  ) : (
                    <Badge tone="muted">not in this beta</Badge>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table></div>
        <p className="note">{pack.talents.note}</p>
      </section>

      <section className="card">
        <SectionTitle aside={findings.length > 5 ? `showing 5 of ${findings.length}` : null}>Recent findings</SectionTitle>
        {recent.length === 0 ? (
          <Empty>Nothing logged yet. The Journal tab takes a title and nothing else.</Empty>
        ) : (
          <ul className="list">
            {recent.map((finding) => (
              <li key={finding.id} className="list__row">
                <span>
                  <Badge tone={finding.severity === 'blocker' ? 'bad' : finding.severity === 'major' ? 'warn' : 'muted'}>
                    {finding.severity}
                  </Badge>{' '}
                  {finding.title}
                  {finding.contentName ? <span className="muted"> — {finding.contentName}</span> : null}
                </span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}
