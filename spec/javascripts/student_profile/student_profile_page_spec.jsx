import _ from 'lodash';
import {studentProfile, nowMoment} from './fixtures.jsx';
import SpecSugar from '../support/spec_sugar.jsx';

describe('StudentProfilePage integration test', function() {
  const ReactDOM = window.ReactDOM;
  const PageContainer = window.shared.PageContainer;

  const helpers = {
    renderStudentProfilePage: function(el, grade, dibels, absencesCount, sectionsCount, schoolType) {
      const serializedData = _.cloneDeep(studentProfile);
      if (grade !== undefined) {
        serializedData["student"]["grade"] = grade;
      }

      if (dibels !== undefined) {
        serializedData["dibels"] = dibels;
      }

      if (absencesCount !== undefined) {
        serializedData["student"]["absences_count"] = absencesCount;
      }

      if (sectionsCount !== undefined) {
        const sections = _.times(sectionsCount, function(n) {
          return {id: n+1};
        });
        serializedData["sections"] = sections;
      }

      if (schoolType !== undefined) {
        serializedData["student"]["school_type"] = schoolType;
      }


      const mergedProps = {
        serializedData: serializedData,
        nowMomentFn: function() { return nowMoment; },
        queryParams: {},
        history: SpecSugar.history()
      };
      ReactDOM.render(<PageContainer {...mergedProps} />, el);
    }
  };

  SpecSugar.withTestEl('renders attendance event summaries correctly', function() {

    describe('student with no absences this school year', function () {
      it('displays zero absences', function () {
        const el = this.testEl;
        helpers.renderStudentProfilePage(el, null, [], 0);
        expect(el).toContainText('Absences this school year:0');
      });
    });

    describe('student with 15 absences this school year', function () {
      it('displays 15 absences', function () {
        const el = this.testEl;
        helpers.renderStudentProfilePage(el);
        expect(el).toContainText('Absences this school year:15');
      });
    });

  });

  SpecSugar.withTestEl('renders MCAS/DIBELS correctly according to grade level', function() {

    describe('student in grade 3', function() {

      describe('student with DIBELS result', function() {
        it('renders the latest DIBELS', function () {
          const el = this.testEl;
          helpers.renderStudentProfilePage(el, '3', [{ 'performance_level': 'INTENSIVE '}]);
          expect(el).not.toContainText('MCAS ELA SGP');
          expect(el).toContainText('DIBELS');
          expect(el).toContainText('INTENSIVE');
        });

      });

      describe('student without DIBELS result', function() {
        it('renders MCAS ELA SGP', function () {
          const el = this.testEl;
          helpers.renderStudentProfilePage(el, '3', []);
          expect(el).toContainText('MCAS ELA SGP');
        });
      });

    });

    describe('student in grade 5', function() {

      describe('student with DIBELS result', function() {
        it('renders MCAS ELA SGP', function () {
          const el = this.testEl;
          helpers.renderStudentProfilePage(el, '5', [{ 'performance_level': 'INTENSIVE '}]);
          expect(el).toContainText('MCAS ELA SGP');
        });
      });

      describe('student without DIBELS result', function() {
        it('renders MCAS ELA SGP', function () {
          const el = this.testEl;
          helpers.renderStudentProfilePage(el, '5', []);
          expect(el).toContainText('MCAS ELA SGP');
        });
      });

      describe('student with sections', function() {
        it('does not have sections count', function() {
          const el = this.testEl;
          helpers.renderStudentProfilePage(el, '5', [], 0, 3, 'ES');
          expect(el).not.toContainText('Sections');
        });
      });
    });

    describe('student in high school', function() {
      it('renders student with 1 section', function() {
        const el = this.testEl;
        helpers.renderStudentProfilePage(el, '10', [], 0, 1, 'HS');
        expect(el).toContainText('1 section');
      });

      it('renders student with 5 sections', function() {
        const el = this.testEl;
        helpers.renderStudentProfilePage(el, '10', [], 0, 5, 'HS');
        expect(el).toContainText('5 sections');
      });
    });
  });
});
