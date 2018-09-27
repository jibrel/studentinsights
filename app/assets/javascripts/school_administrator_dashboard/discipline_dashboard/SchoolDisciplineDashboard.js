import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import moment from 'moment';
import Select from 'react-select';
import 'react-select/dist/react-select.css';
import SelectTimeRange, {
  momentRange,
  TIME_RANGE_45_DAYS_AGO
} from '../../components/SelectTimeRange';
import SelectDisciplineIncidentType from '../../components/SelectDisciplineIncidentType';
import memoizer from '../../helpers/memoizer';
import FilterBar from '../../components/FilterBar';
import {sortByGrade} from '../../helpers/SortHelpers';
import ExperimentalBanner from '../../components/ExperimentalBanner';
import SectionHeading from '../../components/SectionHeading';
import EscapeListener from '../../components/EscapeListener';
import StudentsTable from '../StudentsTable';
import DashboardBarChart from '../DashboardBarChart';
import * as dashboardStyles from '../dashboardStyles';


export default class SchoolDisciplineDashboard extends React.Component {

  constructor(props) {
    super(props);
    this.state = initialState();

    this.onTimeRangeKeyChanged = this.onTimeRangeKeyChanged.bind(this);
    this.selectIncidentCode = this.selectIncidentCode.bind(this);
    this.onResetFilters = this.onResetFilters.bind(this);
    this.setStudentList = this.setStudentList.bind(this);
    this.resetStudentList = this.resetStudentList.bind(this);
    this.selectChart = this.selectChart.bind(this);
    this.memoize = memoizer();
  }

  selectIncidentCode(incidentType) {
    this.setState({selectedIncidentCode: incidentType});
  }

  setStudentList(highchartsEvent) {
    this.setState({selectedCategory: highchartsEvent.point.category});
  }
  resetStudentList() {
    this.setState({selectedCategory: null});
  }
  selectChart(selection) {
    this.setState({selectedChart: selection.value, selectedCategory: null});
  }

  allDisciplineIncidents() {
    return this.memoize(['allDisciplineIncidents'], () => {
      const {dashboardStudents} = this.props;
      return _.flattenDeep(_.compact(dashboardStudents.map(student => this.mergeDisciplineData(student.discipline_incidents, student))));
    });
  }

  //Associate all attributes that we want to use for incident grouping. More may be added here later.
  mergeDisciplineData(disciplineIncidentsArray, student) {
    //student attributes
    const grade = student.grade;
    const classroom = student.homeroom_label;
    const race = student.race;
    return disciplineIncidentsArray.map(incident => {
      //incident attributes derived from raw incident data
      const exactTime = incident.has_exact_time ? moment.utc(incident.occurred_at).startOf('hour').format('h:mm a') : "Not Logged";
      const day = moment.utc(incident.occurred_at).format("ddd");
      const location = incident.incident_location || "Not Recorded";
      return {...incident, grade, classroom, race, exactTime, day, location};
    });
  }

  filteredDisciplineIncidents(disciplineIncidents) {
    return this.memoize(['filteredIncidents', this.state, arguments], () => {
      const {nowFn} = this.context;
      const {timeRangeKey, selectedIncidentCode} = this.state;
      const range = momentRange(timeRangeKey, nowFn());
      return disciplineIncidents.filter(incident => {
        if (!moment.utc(incident.occurred_at).isBetween(range[0], range[1])) return false;
        if (incident.incident_code !== selectedIncidentCode && selectedIncidentCode !== null) return false;
        return true;
      });
    });
  }

  studentDisciplineIncidentCounts(incidents) {
    let studentDisciplineIncidentCounts = {};

    //if a user selects a category and then moves to a time range with no incidents within that category, return an empty object
    if (!incidents) return studentDisciplineIncidentCounts;
    incidents.forEach((incident) => {
      studentDisciplineIncidentCounts[incident.student_id] = studentDisciplineIncidentCounts[incident.student_id] || 0;
      studentDisciplineIncidentCounts[incident.student_id]++;
    });
    return studentDisciplineIncidentCounts;
  }

  sortChartKeys(groupedIncidents) {
    const chartKeys = Object.keys(groupedIncidents);
    switch(this.state.selectedChart) {
    case 'time': return this.sortedTimes(chartKeys);
    case 'day': return this.sortedDays(chartKeys);
    case 'grade': return this.sortedGrades(chartKeys);
    default: return this.sortedByIncidents(groupedIncidents); //because number of incidents in each category needed here
    }
  }

  sortedDays(chartKeys) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  sortedTimes(chartKeys) {
    //chartKeys will either contain a time like "4:00 pm", "10:00 am", or "Not Logged"
    return chartKeys.sort((a, b) => {
      if (a == "Not Logged") return -1;
      if (b == "Not Logged") return 1;
      return new Date('1970/01/01 ' + a) - new Date('1970/01/01 ' + b);
    });
  }

  sortedGrades(chartKeys) {
    return chartKeys.sort((a,b) => sortByGrade(a,b));
  }

  sortedByIncidents(groupedIncidents) {
    const chartKeys = Object.keys(groupedIncidents);
    return chartKeys.sort((a,b) => {
      return groupedIncidents[b].length - groupedIncidents[a].length;
    });
  }

  //For grades and classrooms, the students table should only show the relevant students
  groupStudents() {
    if (this.state.selectedChart === 'grade' && this.state.selectedCategory) {
      return this.props.dashboardStudents.filter(student => student.grade === this.state.selectedCategory);
    } else if (this.state.selectedChart === 'classroom' && this.state.selectedCategory) {
      return this.props.dashboardStudents.filter(student => student.homeroom_label === this.state.selectedCategory);
    } else return this.props.dashboardStudents;
  }

  onTimeRangeKeyChanged(timeRangeKey) {
    this.setState({timeRangeKey});
  }

  onResetFilters() {
    this.setState(initialState());
  }

  render() {
    const {timeRangeKey} = this.state;
    const {school} = this.props;
    const chartOptions = [
      {value: 'incident_location', label: 'Location'},
      {value: 'exactTime', label: 'Time'},
      {value: 'classroom', label: 'Classroom'},
      {value: 'grade', label: 'Grade'},
      {value: 'day', label: 'Day'},
      {value: 'offense', label: 'Offense'},
    ];
    const allIncidents = this.allDisciplineIncidents();
    const filteredIncidents = this.filteredDisciplineIncidents(allIncidents);
    const groupedIncidents = _.groupBy(filteredIncidents, this.state.selectedChart);
    const incidentTypes = _.uniq(allIncidents.map(incident => incident.incident_code));

    return(
      <EscapeListener className="SchoolDisciplineDashboard" style={styles.flexVertical} onEscape={this.onResetFilters}>
        <ExperimentalBanner />
        <div style={{...styles.flexVertical, paddingLeft: 10, paddingRight: 10}}>
          <SectionHeading>Discipline incidents at {school.name}</SectionHeading>
          <div style={dashboardStyles.filterBar}>
            <FilterBar style={styles.timeRange} >
              <SelectDisciplineIncidentType
              type={this.state.selectedIncidentCode || 'All'}
              onChange={this.selectIncidentCode}
              types={incidentTypes}/>
              <SelectTimeRange
                timeRangeKey={timeRangeKey}
                onChange={this.onTimeRangeKeyChanged} />
            </FilterBar>
          </div>
          <div style={dashboardStyles.columns}>
            <div style={dashboardStyles.rosterColumn}>
              {this.renderStudentDisciplineTable(filteredIncidents, groupedIncidents)}
            </div>
            <div style={dashboardStyles.chartsColumn}>
              <div style={styles.graphTitle}>
                <div style={styles.titleText}>
                  Break down by:
                </div>
                <Select
                  value={this.state.selectedChart}
                  onChange={this.selectChart}
                  options={chartOptions}
                  style={styles.dropdown}
                  clearable={false}
                />
              </div>
             {this.renderDisciplineChart(groupedIncidents)}
            </div>
          </div>
        </div>
      </EscapeListener>
    );
  }

  renderDisciplineChart(incidents) {
    const categories = this.sortChartKeys(incidents);
    const seriesData = categories.map((type) => {
      if (!incidents[type]) return [];
      return [type, incidents[type].length];
    });

    return (
        <DashboardBarChart
          id = "Discipline"
          categories = {{categories: categories}}
          seriesData = {seriesData}
          titleText = {null}
          measureText = {'Number of Incidents'}
          tooltip = {{
            pointFormat: 'Total incidents: <b>{point.y}</b>'}}
          onColumnClick = {this.setStudentList}
          onBackgroundClick = {this.resetStudentList}/>
    );
  }

  renderStudentDisciplineTable(allIncidents, groupedIncidents) {
    const students = this.groupStudents();
    const studentDisciplineIncidentCounts = this.state.selectedCategory ? //if the user is looking at a subgroup of incidents
                                            this.studentDisciplineIncidentCounts(groupedIncidents[this.state.selectedCategory]) :
                                            this.studentDisciplineIncidentCounts(allIncidents);
    let rows =[];
    students.forEach((student) => {
      rows.push({
        id: student.id,
        first_name: student.first_name,
        last_name: student.last_name,
        latest_note: student.latest_note,
        events: studentDisciplineIncidentCounts[student.id] || 0,
        grade: student.grade
      });
    });

    return (
      <StudentsTable
        rows = {rows}
        selectedCategory = {this.state.selectedCategory}
        incidentType={"Incidents"}
        resetFn={this.resetStudentList}/>
    );
  }
}
SchoolDisciplineDashboard.contextTypes = {
  nowFn: PropTypes.func.isRequired
};
SchoolDisciplineDashboard.propTypes = {
  dashboardStudents: PropTypes.array.isRequired,
  school: PropTypes.shape({
    name: PropTypes.string.isRequired
  }).isRequired
};

const styles = {
  flexVertical: {
    flex: 1,
    width: '100%',
    display: 'flex',
    flexDirection: 'column'
  },
  timeRange: {
    width: '100%',
    display: 'flex',
    justifyContent: 'flex-end'
  },
  graphTitle: {
    display: 'flex',
    justifyContent: 'center',
    marginTop: '20px'
  },
  titleText: {
    fontSize: '18px',
    marginRight: '10px',
    alignSelf: 'center'
  },
  dropdown: {
    width: '200px'
  }
};

function initialState() {
  return {
    timeRangeKey: TIME_RANGE_45_DAYS_AGO,
    selectedChart: 'incident_location',
    selectedIncidentCode: null,
    selectedCategory: null
  };
}
