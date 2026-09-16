// Turning a journal into something a human will actually read.
//
// Blizzard has not opened a beta feedback forum for Forever yet, so the export target is
// deliberately plain markdown: it pastes into a forum post, a Discord thread, an in-game bug
// report, or an email, and it survives all four. Findings carry the build they were seen on
// because a report without a build stamp is unactionable.

import { sortFindings } from './journal.js';

const TYPE_LABELS = {
  bug: 'Bug',
  quest: 'Quest',
  tuning: 'Tuning',
  text: 'Text',
  ui: 'UI',
  feedback: 'Feedback',
};

function characterLine(character, pack) {
  if (!character) return null;
  const race = (pack?.races ?? []).find((entry) => entry.id === character.raceId);
  const parts = [character.name, race?.name, character.className, character.level ? `level ${character.level}` : null];
  return parts.filter(Boolean).join(' · ');
}

function findingBlock(finding, index, { pack, characters }) {
  const lines = [`### ${index}. ${finding.title}`, ''];
  const facts = [
    `**Type:** ${TYPE_LABELS[finding.type] ?? finding.type}`,
    `**Severity:** ${finding.severity}`,
    finding.contentName ? `**Where:** ${finding.contentName}` : null,
    finding.level ? `**Level:** ${finding.level}` : null,
    finding.gameBuild ? `**Build:** ${finding.gameBuild}` : null,
    finding.reproducible && finding.reproducible !== 'unknown' ? `**Reproducible:** ${finding.reproducible}` : null,
  ].filter(Boolean);
  lines.push(facts.join(' · '), '');

  const character = characters?.find((entry) => entry.id === finding.characterId);
  const who = characterLine(character, pack);
  if (who) lines.push(`**Character:** ${who}`, '');

  if (finding.steps) {
    lines.push('**Steps**', '');
    const steps = finding.steps.split('\n').map((step) => step.trim()).filter(Boolean);
    steps.forEach((step, position) => lines.push(`${position + 1}. ${step.replace(/^\d+[.)]\s*/, '')}`));
    lines.push('');
  }
  if (finding.expected) lines.push(`**Expected:** ${finding.expected}`, '');
  if (finding.actual) lines.push(`**Actual:** ${finding.actual}`, '');
  if (finding.tags?.length) lines.push(`_Tags: ${finding.tags.join(', ')}_`, '');

  return lines.join('\n').trimEnd();
}

/** A forum-ready markdown report for the given findings. */
export function toForumPost(findings, { pack, characters = [], title, day } = {}) {
  const ordered = sortFindings(findings);
  if (ordered.length === 0) return '';

  const builds = [...new Set(ordered.map((finding) => finding.gameBuild).filter(Boolean))];
  const header = [
    `# ${title ?? 'Forever beta feedback'}`,
    '',
    [
      `${ordered.length} finding${ordered.length === 1 ? '' : 's'}`,
      builds.length ? `build ${builds.join(', ')}` : null,
      day ? `logged through ${day}` : null,
    ]
      .filter(Boolean)
      .join(' · '),
    '',
  ];

  const bySeverity = new Map();
  for (const finding of ordered) {
    if (!bySeverity.has(finding.severity)) bySeverity.set(finding.severity, []);
    bySeverity.get(finding.severity).push(finding);
  }

  const body = [];
  let index = 1;
  for (const [severity, group] of bySeverity) {
    body.push(`## ${severity[0].toUpperCase()}${severity.slice(1)} (${group.length})`, '');
    for (const finding of group) {
      body.push(findingBlock(finding, index, { pack, characters }), '');
      index += 1;
    }
  }

  return [...header, ...body].join('\n').replace(/\n{3,}/g, '\n\n').trimEnd() + '\n';
}

/** One-line-per-finding digest, for pasting into chat rather than a forum. */
export function toDigest(findings) {
  return sortFindings(findings)
    .map((finding) => {
      const where = finding.contentName ? ` (${finding.contentName})` : '';
      return `- [${finding.severity}] ${finding.title}${where}`;
    })
    .join('\n');
}
