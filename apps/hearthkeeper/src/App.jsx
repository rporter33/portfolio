import { useMemo, useState } from 'react';
import pack from './data/pack.2026-09-17.json';
import { computeCoverage } from './core/coverage.js';
import { today } from './core/dates.js';
import { resolveSchedule } from './core/schedule.js';
import { useAppState } from './state.js';
import Coverage from './ui/Coverage.jsx';
import Dashboard from './ui/Dashboard.jsx';
import DataTab from './ui/DataTab.jsx';
import Journal from './ui/Journal.jsx';
import Roster from './ui/Roster.jsx';

const TABS = [
  { id: 'now', label: 'Now' },
  { id: 'journal', label: 'Journal' },
  { id: 'roster', label: 'Roster' },
  { id: 'coverage', label: 'Coverage' },
  { id: 'data', label: 'Data' },
];

export default function App() {
  const { state, actions, backup, storageHealthy } = useAppState(pack);
  const [tab, setTab] = useState('now');

  const day = today();
  const schedule = useMemo(() => resolveSchedule(pack, day), [day]);
  const coverage = useMemo(
    () =>
      computeCoverage({
        pack,
        findings: state.findings,
        characters: state.characters,
        levelCap: schedule.levelCap,
      }),
    [state.findings, state.characters, schedule.levelCap],
  );

  return (
    <div className="app">
      <header className="app__header">
        <div>
          <h1>Hearthkeeper</h1>
          <p className="app__tagline">Field journal for the Forever beta · everything stays in this browser</p>
        </div>
        <p className="app__phase">
          {schedule.status === 'live'
            ? `${schedule.phase.name} · cap ${schedule.levelCap}`
            : schedule.status === 'before'
              ? `opens in ${schedule.daysUntilStart}d`
              : schedule.status === 'ended'
                ? 'beta closed'
                : 'no schedule'}
        </p>
      </header>

      <nav className="tabs" aria-label="Sections">
        {TABS.map((entry) => (
          <button
            key={entry.id}
            type="button"
            className={`tab ${tab === entry.id ? 'tab--active' : ''}`}
            aria-current={tab === entry.id ? 'page' : undefined}
            onClick={() => setTab(entry.id)}
          >
            {entry.label}
            {entry.id === 'journal' && state.findings.length ? <span className="tab__count">{state.findings.length}</span> : null}
          </button>
        ))}
      </nav>

      <main className="app__main">
        {tab === 'now' ? (
          <Dashboard pack={pack} schedule={schedule} coverage={coverage} findings={state.findings} onGoTo={setTab} />
        ) : null}
        {tab === 'journal' ? (
          <Journal pack={pack} findings={state.findings} characters={state.characters} actions={actions} day={day} />
        ) : null}
        {tab === 'roster' ? (
          <Roster pack={pack} characters={state.characters} actions={actions} levelCap={schedule.levelCap} />
        ) : null}
        {tab === 'coverage' ? <Coverage coverage={coverage} levelCap={schedule.levelCap} /> : null}
        {tab === 'data' ? (
          <DataTab
            pack={pack}
            snapshot={state.packSnapshot}
            state={state}
            backup={backup}
            actions={actions}
            storageHealthy={storageHealthy}
          />
        ) : null}
      </main>

      <footer className="app__footer">
        <p>
          Hearthkeeper is an unofficial fan tool. Not affiliated with or endorsed by Blizzard Entertainment. Game data is
          compiled from public announcements and carries a confidence flag on every row.
        </p>
      </footer>
    </div>
  );
}
