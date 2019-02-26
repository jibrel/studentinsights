import React from 'react';
import ReactDOM from 'react-dom';
import renderer from 'react-test-renderer';
import _ from 'lodash';
import {withDefaultNowContext} from '../testing/NowContainer';
import serviceTypesIndex from '../testing/fixtures/serviceTypesIndex';
import FixtureStudents from './schoolOverviewStudents.fixture';
import SlicePanels from './SlicePanels';

function testProps(props = {}) {
  return {
    districtKey: 'somerville',
    filters: [],
    serviceTypesIndex,
    school: {
      school_type: 'ES'
    },
    students: [],
    allStudents: [],
    onFilterToggled: jest.fn(),
    ...props
  };
}

function testEl(props) {
  return withDefaultNowContext(<SlicePanels {...props} />);
}

function testRender(props) {
  const el = document.createElement('div');
  ReactDOM.render(testEl(props), el);
  return {el};
}

const helpers = {
  // Returns a matrix of the kinds of things that users can slice by in each
  // column (eg., disability, STAR reading quartile).
  columnTitlesMatrix(el) {
    const columnEls = $(el).find('.column').toArray();
    return columnEls.map(columnEl => {
      return $(columnEl).find('.fixed-table-title').toArray().map(titleEl => {
        return $(titleEl).text();
      });
    });
  },

  // Count how many attributes there are for each table in each column
  // (e.g., how many "Disability" options are there, and how many
  // "STAR Reading" options are there for slicing by.
  rowsPerColumnMatrix(el) {
    const columnEls = $(el).find('.column').toArray();
    return columnEls.map(columnEl => {
      return $(columnEl).find('table').toArray().map(tableEl => {
        return $(tableEl).find('tbody tr').length;
      });
    });
  },

  // Returns an array of text values the users can filter by for student
  // Disability
  disabilityFilters(el) {
    return $(el).find('table:eq(1) td.caption-cell').toArray().map(el => $(el).text());
  }
};

describe('high-level integration tests', () => {
  it(`renders everything on the happy path for elementary school with
      no student registration dates`, () => {
    const {el} = testRender(testProps());

    expect($(el).find('.SlicePanels').length).toEqual(1);
    expect($(el).find('.column').length).toEqual(6);
    expect(helpers.columnTitlesMatrix(el)).toEqual([
      [ '504 plan', 'SPED level', 'English learner', 'Low income' ],
      [ 'Grade', 'Gender', 'Race', 'Hispanic/Latino' ],
      [ 'STAR Reading', 'MCAS ELA Score', 'MCAS ELA SGP' ],
      [ 'STAR Math', 'MCAS Math Score', 'MCAS Math SGP' ],
      [ 'Discipline incidents', 'Absences', 'Tardies' ],
      [ 'Services', 'Summer', 'Notes', 'Program', 'Homeroom' ]
    ]);
  });

  it(`renders everything on the happy path for elementary school with
       student registration dates`, () => {

    const studentsWithRegistration = FixtureStudents.map((student) => {
      return _.merge(student, {registration_date: '2018-02-13T22:17:30.338Z'});
    });

    const {el} = testRender(testProps({
      students: studentsWithRegistration,
      allStudents: studentsWithRegistration
    }));

    expect($(el).find('.SlicePanels').length).toEqual(1);
    expect($(el).find('.column').length).toEqual(6);
    expect(helpers.columnTitlesMatrix(el)).toEqual([
      [ '504 plan', 'SPED level', 'English learner', 'Low income', 'Years enrolled' ],
      [ 'Grade', 'Gender', 'Race', 'Hispanic/Latino' ],
      [ 'STAR Reading', 'MCAS ELA Score', 'MCAS ELA SGP' ],
      [ 'STAR Math', 'MCAS Math Score', 'MCAS Math SGP' ],
      [ 'Discipline incidents', 'Absences', 'Tardies' ],
      [ 'Services', 'Summer', 'Notes', 'Program', 'Homeroom' ]
    ]);
  });

  it('renders everything on the happy path for high school', () => {
    const {el} = testRender(testProps({
      school: {
        school_type: 'HS',
        local_id: 'SHS'
      }
    }));

    expect($(el).find('.SlicePanels').length).toEqual(1);
    expect($(el).find('.column').length).toEqual(6);
    expect(helpers.columnTitlesMatrix(el)).toEqual([
      [ '504 plan', 'SPED level', 'English learner', 'Low income' ],
      [ 'Grade', 'House', 'Counselor', 'Gender', 'Race', 'Hispanic/Latino' ],
      [ 'STAR Reading', 'MCAS ELA Score', 'MCAS ELA SGP' ],
      [ 'STAR Math', 'MCAS Math Score', 'MCAS Math SGP' ],
      [ 'Discipline incidents', 'Absences', 'Tardies' ],
      [ 'Services', 'Summer', 'Notes', 'Program', 'Homeroom' ]
    ]);
  });

  it('renders attributes for slicing based on student data', () => {
    const {el} = testRender(testProps({
      students: FixtureStudents,
      allStudents: FixtureStudents
    }));

    expect(helpers.rowsPerColumnMatrix(el)).toEqual([
      [2, 5, 3, 4, 1],
      [3, 3, 3, 3],
      [5, 5, 5],
      [5, 5, 5],
      [5, 5, 5],
      [3, 4, 3, 3, 3]
    ]);
  });

  describe('disability values vary by district', () => {
    it('renders values with None for Somerville', () => {
      const {el} = testRender(testProps({
        districtKey: 'somerville',
        students: FixtureStudents,
        allStudents: FixtureStudents
      }));
      expect(helpers.disabilityFilters(el)).toEqual([
        "None",
        "Low < 2",
        "Low >= 2",
        "Moderate",
        "High"
      ]);
    });

    it('renders explicit values only for New Bedford', () => {
      const {el} = testRender(testProps({
        districtKey: 'new_bedford',
        students: FixtureStudents,
        allStudents: FixtureStudents
      }));
      expect(helpers.disabilityFilters(el)).toEqual([
        "Does Not Apply",
        "Low-Less Than 2hrs/week",
        "Low-2+ hrs/week",
        "Moderate",
        "High"
      ]);
    });

    it('renders explicit values only for Bedford', () => {
      const {el} = testRender(testProps({
        districtKey: 'bedford',
        students: FixtureStudents,
        allStudents: FixtureStudents
      }));
      expect(helpers.disabilityFilters(el)).toEqual([
        'Does Not Apply',
        'Low (2 hours or less)',
        'Low (2 or more hours)',
        'Moderate',
        'High'
      ]);
    });
  });
});

it('matches snapshot', () => {
  const props = testProps({
    students: FixtureStudents,
    allStudents: FixtureStudents
  });
  const tree = renderer
    .create(testEl(props))
    .toJSON();
  expect(tree).toMatchSnapshot();
});