import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import {apiFetchJson} from '../helpers/apiFetchJson';
import SectionHeading from '../components/SectionHeading';
import GenericLoader from '../components/GenericLoader';
import RollbarErrorBoundary from '../components/RollbarErrorBoundary';
import ReaderProfileJune from './ReaderProfileJune';
import ReaderProfileOctober from './ReaderProfileOctober';


export default class ReaderProfileJunePage extends React.Component {
  render() {
    const {student} = this.props;
    const url = `/api/students/${student.id}/reader_profile_json`;

    return (
      <RollbarErrorBoundary debugKey="ReaderProfileJunePage">
        <div className="ReaderProfileJunePage">
          <SectionHeading>Reader Profile, v3</SectionHeading>
          <GenericLoader
            promiseFn={() => apiFetchJson(url)}
            render={json => this.renderJson(json)} />
        </div>
      </RollbarErrorBoundary>
    );
  }

  renderJson(json) {
    const {student} = this.props;

    return (
      <div>
        <ReaderProfileJune
          student={student}
          access={json.access}
          services={json.services}
          iepContents={json.iep_contents}
          feedCards={json.feed_cards}
          currentSchoolYear={json.current_school_year}
          dataPointsByAssessmentKey={_.groupBy(json.benchmark_data_points, 'benchmark_assessment_key')}
        />
        <ReaderProfileOctober
          student={student}
          access={json.access}
          services={json.services}
          iepContents={json.iep_contents}
          feedCards={json.feed_cards}
          currentSchoolYear={json.current_school_year}
          dataPointsByAssessmentKey={_.groupBy(json.benchmark_data_points, 'benchmark_assessment_key')}
        />
      </div>
    );
  }
}
ReaderProfileJunePage.propTypes = {
  student: PropTypes.shape({
    id: PropTypes.number.isRequired,
    grade: PropTypes.any.isRequired
  }).isRequired
};
