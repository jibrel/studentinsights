import _ from 'lodash';
import moment from 'moment';
import {
  high,
  medium,
  low,
  missing
} from '../helpers/colors';
import {
  toSchoolYear,
  firstDayOfSchool,
  lastDayOfSchool
} from '../helpers/schoolYear';
import {
  INSTRUCTIONAL_NEEDS,
  F_AND_P_ENGLISH,
  F_AND_P_SPANISH,
  DIBELS_DORF_WPM,
  DIBELS_DORF_ACC,
  DIBELS_DORF_ERRORS,
  DIBELS_FSF,
  DIBELS_LNF,
  DIBELS_PSF,
  DIBELS_NWF_CLS,
  DIBELS_NWF_WWR,
  somervilleReadingThresholdsFor
} from './thresholds';


const ORDERED_F_AND_P_ENGLISH_LEVELS = {
  'NR': 50,
  'AA': 80,
  'A': 110,
  'B': 120,
  'C': 130,
  'D': 150,
  'E': 160,
  'F': 170,
  'G': 180,
  'H': 190,
  'I': 200,
  'J': 210,
  'K': 220,
  'L': 230,
  'M': 240,
  'N': 250,
  'O': 260,
  'P': 270,
  'Q': 280,
  'R': 290,
  'S': 300,
  'T': 310,
  'U': 320,
  'V': 330,
  'W': 340,
  'X': 350,
  'Y': 360,
  'Z': 370 // Z+ is also a special case per F&P docs, but ignore it for now since folks use + a lot of different places
};

// benchmark_assessment_key values:
export function readDoc(doc, studentId, benchmarkAssessmentKey) {
  return (doc[studentId] || {})[benchmarkAssessmentKey] || '';
}

export function prettyDibelsText(benchmarkAssessmentKey) {
  return {
    [DIBELS_FSF]: 'First Sound Fluency',
    [DIBELS_LNF]: 'Letter Naming Fluency',
    [DIBELS_PSF]: 'Phonemic Segmentation Fluency',
    [DIBELS_NWF_CLS]: 'Nonsense Word Fluency Correct Letter Sounds',
    [DIBELS_NWF_WWR]: 'Nonsense Word Fluency Whole Words Read',
    [DIBELS_DORF_WPM]: 'Oral Reading Fluency',
    [DIBELS_DORF_ACC]: 'Oral Reading Accuracy'
  }[benchmarkAssessmentKey];
}
export function shortDibelsText(benchmarkAssessmentKey) {
  return {
    [DIBELS_FSF]: 'FSF',
    [DIBELS_LNF]: 'LNF',
    [DIBELS_PSF]: 'PSF',
    [DIBELS_NWF_CLS]: 'NWF cls',
    [DIBELS_NWF_WWR]: 'NWF wwr',
    [DIBELS_DORF_WPM]: 'ORF wpm',
    [DIBELS_DORF_ACC]: 'ORF acc',
    [DIBELS_DORF_ERRORS]: 'ORF errors',
    [F_AND_P_ENGLISH]: 'F&P English',
    [F_AND_P_SPANISH]: 'F&P Spanish',
    [INSTRUCTIONAL_NEEDS]: 'Instructional needs',
  }[benchmarkAssessmentKey];
}


/*
classifications - these use the language of "composite" but are
not the same, which is a bit misleading.  also, beware that...

"Because the scores used to calculate the DIBELS Composite Score vary
by grade and time of year, it is important to note that the composite
score generally cannot be used to directly measure growth over time
or to compare results across grades or times of year. However,
because the logic and procedures used to establish benchmark goals
are consistent across grades and times of year, the percent of
students at or above benchmark can be compared, even though the
mean scores are not comparable."
*/

export const DIBELS_CORE = 'DIBELS_CORE';
export const DIBELS_STRATEGIC = 'DIBELS_STRATEGIC';
export const DIBELS_INTENSIVE = 'DIBELS_INTENSIVE';
export const DIBELS_UNKNOWN = 'DIBELS_UNKNOWN';

// deprecated
export function classifyDibels(text, benchmarkAssessmentKey, grade, benchmarkPeriodKey) {
  // interpret
  if (!text) return DIBELS_UNKNOWN;
  const value = interpretDibels(text);
  if (!value) return DIBELS_UNKNOWN;

  // classify
  const thresholds = somervilleReadingThresholdsFor(benchmarkAssessmentKey, grade, benchmarkPeriodKey);
  if (!thresholds) return DIBELS_UNKNOWN;
  if (value >= thresholds.benchmark) return DIBELS_CORE;
  if (value <= thresholds.risk) return DIBELS_INTENSIVE;
  return DIBELS_STRATEGIC;
}

export const DIBELS_GREEN = 'dibels_green';
export const DIBELS_YELLOW = 'dibels_yellow';
export const DIBELS_RED = 'dibels_red';
export function bucketForDibels(text, benchmarkAssessmentKey, grade, benchmarkPeriodKey) {
  // interpret
  if (!text) return DIBELS_UNKNOWN;
  const value = interpretDibels(text);
  if (value === null || value === undefined) return DIBELS_UNKNOWN;

  // classify
  const thresholds = somervilleReadingThresholdsFor(benchmarkAssessmentKey, grade, benchmarkPeriodKey);
  if (!thresholds) return DIBELS_UNKNOWN;
  if (value >= thresholds.benchmark) return DIBELS_GREEN;
  if (value <= thresholds.risk) return DIBELS_RED;
  return DIBELS_YELLOW;
}


export function interpretDibels(text) {
  return parseInt(text.replace(/%/g, '').toUpperCase().trim(), 10);
}

export function colorForDibelsCategory(category) {
  return {
    [DIBELS_CORE]: high,
    [DIBELS_STRATEGIC]: medium,
    [DIBELS_INTENSIVE]: low,
    [DIBELS_UNKNOWN]: missing
  }[category] || missing;
}

export function dibelsColor(value, thresholds) {
  if (value >= thresholds.benchmark) return high;
  if (value <= thresholds.risk) return low;
  return medium;
}

export function classifyFAndPEnglish(level, grade, benchmarkPeriodKey) {
  if (!ORDERED_F_AND_P_ENGLISH_LEVELS[level]) return null;
  const thresholds = somervilleReadingThresholdsFor(F_AND_P_ENGLISH, grade, benchmarkPeriodKey);
  if (!thresholds) return null;

  if (ORDERED_F_AND_P_ENGLISH_LEVELS[level] >= ORDERED_F_AND_P_ENGLISH_LEVELS[thresholds.benchmark]) return 'high';

  // might not be a "risk"
  if (thresholds.risk && ORDERED_F_AND_P_ENGLISH_LEVELS[level] <= ORDERED_F_AND_P_ENGLISH_LEVELS[thresholds.risk]) return 'low';
  return 'medium';
}

// For interpreting user input like A/C or A+ or H(indep) or B-C
// for each, round down (latest independent 'mastery' level)
// if not found in list of levels and can't understand, return null
export function interpretFAndPEnglish(text) {
  // always trim whitespace
  if (text.length !== text.trim().length) return interpretFAndPEnglish(text.trim());

  // F, NR, AA (exact match)
  const exactMatch = strictMatchForFAndPLevel(text);
  if (exactMatch) return exactMatch;

  // F+
  if (_.endsWith(text, '+')) {
    return strictMatchForFAndPLevel(text.slice(0, -1));
  }

  // F?
  if (_.endsWith(text, '?')) {
    return strictMatchForFAndPLevel(text.slice(0, -1));
  }

  // F-G or F/G
  if (text.indexOf('/') !== -1) return strictMatchForFAndPLevel(text.split('/')[0]);
  if ((text.indexOf('-') !== -1)) return strictMatchForFAndPLevel(text.split('-')[0]);

  // F (indep) or F (instructional)
  if ((text.indexOf('(') !== -1)) {
    return strictMatchForFAndPLevel(text.replace(/\([^)]+\)/g, ''));
  }

  return null;
}

// Only letters and whitespace, no other characters
function strictMatchForFAndPLevel(text) {
  const trimmed = text.trim();
  return (_.has(ORDERED_F_AND_P_ENGLISH_LEVELS, trimmed.toUpperCase()))
    ? trimmed.toUpperCase()
    : null;
}

export function orderedFAndPLevels() {
  return _.sortBy(Object.keys(ORDERED_F_AND_P_ENGLISH_LEVELS), level => ORDERED_F_AND_P_ENGLISH_LEVELS[level]);
}

// see ReadingBenchmarkDataPoint#benchmark_period_key_at
export function benchmarkPeriodKeyFor(timeMoment) {
  const year = toSchoolYear(timeMoment);
  const fallStart = firstDayOfSchool(year);
  const winterStart = toMoment([year+1, 1, 1]);
  const springStart = toMoment([year+1, 5, 1]);
  const summerStart = lastDayOfSchool(year);

  if (timeMoment.isBetween(fallStart, winterStart)) return 'fall';
  if (timeMoment.isBetween(winterStart, springStart)) return 'winter';
  if (timeMoment.isBetween(springStart, summerStart)) return 'spring';
  return 'summer';
}

export function benchmarkPeriodToMoment(benchmarkPeriodKey, schoolYear) {
  if (benchmarkPeriodKey === 'fall') return toMoment([schoolYear, 9, 1]);
  if (benchmarkPeriodKey === 'winter') return toMoment([schoolYear+1, 1, 1]);
  if (benchmarkPeriodKey === 'spring') return toMoment([schoolYear+1, 5, 1]);
  if (benchmarkPeriodKey === 'summer') return lastDayOfSchool(schoolYear);
  return null;
}

export function previousTimePeriod(benchmarkPeriodKey, schoolYear) {
  if (benchmarkPeriodKey === 'fall') return ['summer', schoolYear - 1];
  if (benchmarkPeriodKey === 'winter') return ['fall', schoolYear];
  if (benchmarkPeriodKey === 'spring') return ['winter', schoolYear];
  if (benchmarkPeriodKey === 'summer') return ['spring', schoolYear];
  return null;
}

export function nextTimePeriod(benchmarkPeriodKey, schoolYear) {
  if (benchmarkPeriodKey === 'fall') return ['winter', schoolYear];
  if (benchmarkPeriodKey === 'winter') return ['spring', schoolYear];
  if (benchmarkPeriodKey === 'spring') return ['summer', schoolYear];
  if (benchmarkPeriodKey === 'summer') return ['fall', schoolYear + 1];
  return null;
}

function toMoment(triple) {
  return moment.utc([triple[0], triple[1], triple[2]].join('-'), 'YYYY-M-D');
}


// For `_.orderBy` sorting
export function rankBenchmarkDataPoint(d) {
  const benchmarkAssessmentKey = d.benchmark_assessment_key;
  const text = d.json ? d.json.value : null;
  if (benchmarkAssessmentKey === INSTRUCTIONAL_NEEDS) {
    return text || -1;
  }

  if (benchmarkAssessmentKey === F_AND_P_ENGLISH || benchmarkAssessmentKey === F_AND_P_SPANISH) {
    const level = interpretFAndPEnglish(text);
    if (!level) return -1;
    return ORDERED_F_AND_P_ENGLISH_LEVELS[level] || -1;
  }

  // dibels
  const value = interpretDibels(text);
  return (value === null || value === undefined) ? -1 : value;
}