import React from 'react';
import PropTypes from 'prop-types';

import DashboardHelpers from '../DashboardHelpers';
import SchoolTardiesDashboard from './SchoolTardiesDashboard';

class SchoolwideTardies extends React.Component {

  schoolTardyEvents() {
    const studentRecords = this.props.dashboardStudents;
    return DashboardHelpers.tardyEventsByDay(studentRecords);
  }

  render() {
    return (
      <SchoolTardiesDashboard
        schoolTardyEvents = {this.schoolTardyEvents()}
        dashboardStudents = {this.props.dashboardStudents}
        school={this.props.school} />);
  }
}

SchoolwideTardies.propTypes = {
  dashboardStudents: PropTypes.array.isRequired,
  school: PropTypes.object.isRequired
};

export default SchoolwideTardies;
