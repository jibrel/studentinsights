import React from 'react';
import PropTypes from 'prop-types';

const TEAM_ICON_MAP = {
  'Competitive Cheerleading Varsity': '📣',
  'Cross Country - Boys Varsity': '👟',
  'Cross Country - Girls Varsity': '👟',
  'Football Varsity': '🏈',
  'Golf Varsity': '⛳',
  'Soccer - Boys Freshman': '⚽',
  'Soccer - Boys JV': '⚽',
  'Soccer - Boys Varsity': '⚽',
  'Soccer - Girls JV': '⚽',
  'Soccer - Girls Varsity': '⚽',
  'Volleyball - Girls Freshman': '🏐',
  'Volleyball - Girls JV': '🏐',
  'Volleyball - Girls Varsity': '🏐'
};


export default function Team({team, style}) {
  return (
    <span title={`${team.activity_text} with ${team.coach_text}`}>
      <TeamIcon team={team} style={{paddingRight: 5}} />
      {parseTeam(team.activity_text)}
    </span>
  );
}
Team.propTypes = {
  team: PropTypes.shape({
    activity_text: PropTypes.string.isRequired,
    coach_text: PropTypes.string.isRequired
  }).isRequired,
  style: PropTypes.object
};


export function TeamIcon({team, style}) {
  const teamKey = team.activity_text;
  const emoji = TEAM_ICON_MAP[teamKey] || '🏅';
  return (
    <span
      title={`${team.activity_text} with ${team.coach_text}`}
      style={{cursor: 'default', ...style}}>
      {emoji}
    </span>
  );
}
TeamIcon.propTypes = {
  team: PropTypes.shape({
    activity_text: PropTypes.string.isRequired,
    coach_text: PropTypes.string.isRequired
  }).isRequired,
  style: PropTypes.object
};


export function parseTeam(activityText) {
  return activityText
    .replace(' - ', ' ')
    .replace('Boys', '')
    .replace('Girls', '')
    .replace('Varsity', '')
    .replace('JV', '')
    .replace('Freshman', '')
    .trim();
}