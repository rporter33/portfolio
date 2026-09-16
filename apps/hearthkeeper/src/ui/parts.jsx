// Small shared pieces. Kept deliberately plain: no component library, no runtime CSS-in-JS.

export function Badge({ tone = 'neutral', children, title }) {
  return (
    <span className={`badge badge--${tone}`} title={title}>
      {children}
    </span>
  );
}

const CONFIDENCE_TONE = {
  announced: 'ok',
  reported: 'warn',
  'carried-over': 'warn',
  unconfirmed: 'muted',
};

/** Provenance, shown inline everywhere game data appears. */
export function Confidence({ level, note }) {
  if (!level) return null;
  return (
    <Badge tone={CONFIDENCE_TONE[level] ?? 'muted'} title={note ?? confidenceHelp(level)}>
      {level}
    </Badge>
  );
}

export function confidenceHelp(level) {
  switch (level) {
    case 'announced':
      return 'Stated by Blizzard at announcement.';
    case 'reported':
      return 'Reported in coverage or paraphrased — not a direct statement.';
    case 'carried-over':
      return 'Assumed unchanged from Classic; not confirmed for Forever.';
    default:
      return 'Unconfirmed. Treat as a placeholder.';
  }
}

export function Field({ label, hint, children }) {
  return (
    <label className="field">
      <span className="field__label">{label}</span>
      {children}
      {hint ? <span className="field__hint">{hint}</span> : null}
    </label>
  );
}

export function Empty({ children }) {
  return <p className="empty">{children}</p>;
}

export function SectionTitle({ children, aside }) {
  return (
    <div className="section-title">
      <h2>{children}</h2>
      {aside ? <span className="section-title__aside">{aside}</span> : null}
    </div>
  );
}
