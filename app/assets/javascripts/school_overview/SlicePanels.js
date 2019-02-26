import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import CollapsableTable from './CollapsableTable';
import FixedTable from './FixedTable';
import {styles} from '../helpers/Theme';
import * as Filters from '../helpers/Filters';
import {nextGenMcasScoreRange, oldMcasScoreRange} from '../helpers/mcasScores';
import {shouldDisplayHouse, shouldDisplayCounselor} from '../helpers/PerDistrict';
import {renderSlicePanelsDisabilityTable} from '../helpers/PerDistrict';
import {eventNoteTypeText} from '../helpers/eventNoteType';


// For showing a set of panels that let users see an overview
// of distributions, and click to filter a set of data in different
// ways.
export default class SlicePanels extends React.Component {
  createItem(caption, filter) {
    const students = this.props.students;
    return {
      caption: caption,
      percentage: (students.length === 0) ? 0 : students.filter(filter.filterFn).length / students.length,
      filter: filter
    };
  }

  createItemsFromValues(key, uniqueValues) {
    const items = _.compact(uniqueValues).map(value => {
      return this.createItem(value, Filters.Equal(key, value));
    });
    const itemsWithNull = (_.some(uniqueValues, _.isNull))
      ? items.concat(this.createItem('None', Filters.Null(key)))
      : items;
    const students = this.props.allStudents;
    return _.sortBy(itemsWithNull, function(item) {
      return -1 * students.filter(item.filter.filterFn).length;
    });
  }

  serviceItems() {
    const students = this.props.allStudents;
    const activeServices = _.compact(_.flatten(_.map(students, 'active_services')));
    const activeServiceTypeIds = activeServices.map(service => parseInt(service.service_type_id, 10));
    const allServiceTypeIds = _.pull(_.uniq(activeServiceTypeIds), 508); // Deprecated Math intervention service type

    const serviceItems = allServiceTypeIds.map(serviceTypeId => {
      const serviceName = this.props.serviceTypesIndex[serviceTypeId].name;
      return this.createItem(serviceName, Filters.ServiceType(serviceTypeId));
    });
    const sortedItems =  _.sortBy(serviceItems, function(item) {
      return -1 * students.filter(item.filter.filterFn).length;
    });

    return [this.createItem('None', Filters.ServiceType(null))].concat(sortedItems);
  }

  summerItems () {
    const students = this.props.allStudents;
    const summerServices = _.compact(_.flatten(_.map(students, 'summer_services')));
    const allSummerServiceTypeIds = _.uniq(summerServices.map(service => {
      return parseInt(service.service_type_id, 10);
    }));

    const serviceItems = allSummerServiceTypeIds.map(serviceTypeId => {
      const serviceName = this.props.serviceTypesIndex[serviceTypeId].name;
      return this.createItem(serviceName, Filters.SummerServiceType(serviceTypeId));
    });

    return [this.createItem('None', Filters.SummerServiceType(null))].concat(serviceItems);
  }

  // TODO(kr) add other note types
  mergedNoteItems() {
    const students = this.props.allStudents;
    const allEventNotes = _.compact(_.flatten(_.map(students, 'event_notes')));
    const allEventNoteTypesIds = _.uniq(allEventNotes.map(eventNote => {
      return parseInt(eventNote.event_note_type_id, 10);
    }));
    const eventNoteItems = allEventNoteTypesIds.map(eventNoteTypeId => {
      return this.createItem(eventNoteTypeText(eventNoteTypeId), Filters.EventNoteType(eventNoteTypeId));
    });
    const sortedItems =  _.sortBy(eventNoteItems, function(item) {
      return -1 * students.filter(item.filter.filterFn).length;
    });

    return [this.createItem('None', Filters.EventNoteType(null))].concat(sortedItems);
  }

  MCASFilterItems(key) {
    const nullItem = [this.createItem('None', Filters.Null(key))];
    const nextGenMCASFilters = [
      this.createItem('Not Meeting Expectations', Filters.Range(key, nextGenMcasScoreRange('NM'))),
      this.createItem('Partially Meeting', Filters.Range(key, nextGenMcasScoreRange('PM'))),
      this.createItem('Meeting Expectations', Filters.Range(key, nextGenMcasScoreRange('M'))),
      this.createItem('Exceeding Expectations', Filters.Range(key, nextGenMcasScoreRange('E')))
    ];
    const oldMCASFilters = [
      this.createItem('Warning', Filters.Range(key, oldMcasScoreRange('W'))),
      this.createItem('Needs Improvement', Filters.Range(key, oldMcasScoreRange('NI'))),
      this.createItem('Proficient', Filters.Range(key, oldMcasScoreRange('P'))),
      this.createItem('Advanced', Filters.Range(key, oldMcasScoreRange('A'))),
    ];

    const sortedScores = _.compact(_.map(this.props.students, key)).sort();
    const medianScore = sortedScores[Math.floor(sortedScores.length / 2)];

    if (medianScore > 280) return nullItem.concat(nextGenMCASFilters, oldMCASFilters);

    return nullItem.concat(oldMCASFilters, nextGenMCASFilters);
  }

  render() {
    return (
      <div
        className="SlicePanels columns-container"
        style={{
          display: 'flex',
          width: '100%',
          flexDirection: 'row',
          fontSize: styles.fontSize
        }}>
        {this.renderProfileColumn()}
        {this.renderGradeColumn()}
        {this.renderELAColumn()}
        {this.renderMathColumn()}
        {this.renderAttendanceColumn()}
        {this.renderInterventionsColumn()}
      </div>
    );
  }

  renderProfileColumn() {
    return (
      <div className="column">
        {this.renderSimpleTable('504 plan', 'plan_504', { limit: 4 })}
        {this.renderDisabilityTable()}
        {this.renderSimpleTable('English learner', 'limited_english_proficiency', { limit: 3 })}
        {this.renderSimpleTable('Low income', 'free_reduced_lunch', { limit: 4 })}
        {this.renderYearsEnrolled()}
      </div>
    );
  }

  // This is different based on the values in the data storage system within
  // the district.
  renderDisabilityTable() {
    const {districtKey} = this.props;
    return renderSlicePanelsDisabilityTable(districtKey, {
      createItemFn: this.createItem.bind(this),
      renderTableFn: this.renderTable.bind(this)
    });
  }

  renderELAColumn() {
    return (
      <div className="column ela-background">
        {this.renderPercentileTable('STAR Reading', 'most_recent_star_reading_percentile')}
        {this.renderMCASTable('MCAS ELA Score', 'most_recent_mcas_ela_scaled')}
        {this.renderPercentileTable('MCAS ELA SGP', 'most_recent_mcas_ela_growth')}
      </div>
    );
  }

  renderMathColumn() {
    return (
      <div className="column math-background">
        {this.renderPercentileTable('STAR Math', 'most_recent_star_math_percentile')}
        {this.renderMCASTable('MCAS Math Score', 'most_recent_mcas_math_scaled')}
        {this.renderPercentileTable('MCAS Math SGP', 'most_recent_mcas_math_growth')}
      </div>
    );
  }

  renderPercentileTable(title, key, props = {}) {
    return this.renderTable({
      ...props,
      title: title,
      items: [this.createItem('None', Filters.Null(key))].concat([
        this.createItem('< 25th', Filters.Range(key, [0, 25])),
        this.createItem('25th - 50th', Filters.Range(key, [25, 50])),
        this.createItem('50th - 75th', Filters.Range(key, [50, 75])),
        this.createItem('> 75th', Filters.Range(key, [75, 100]))
      ])
    });
  }

  renderMCASTable(title, key, props = {}) {
    const filterItems = this.MCASFilterItems(key);

    return this.renderTable({
      ...props,
      title: title,
      items: filterItems,
      limit: 5
    });
  }

  renderAttendanceColumn() {
    return (
      <div
        className="column attendance-column attendance-background pad-column-right">
        {this.renderDisciplineTable()}
        {this.renderAttendanceTable('Absences', 'absences_count')}
        {this.renderAttendanceTable('Tardies', 'tardies_count')}
      </div>
    );
  }

  renderDisciplineTable() {
    const key = 'discipline_incidents_count';
    return this.renderTable({
      title: 'Discipline incidents',
      items: [
        this.createItem('0', Filters.Equal(key, 0)),
        this.createItem('1', Filters.Equal(key, 1)),
        this.createItem('2', Filters.Equal(key, 2)),
        this.createItem('3 - 5', Filters.Range(key, [3, 6])),
        this.createItem('6+', Filters.Range(key, [6, Number.MAX_VALUE]))
      ]
    });
  }

  renderAttendanceTable(title, key) {
    return this.renderTable({
      title: title,
      items: [
        this.createItem('0 days', Filters.Equal(key, 0)),
        this.createItem('< 1 week', Filters.Range(key, [1, 5])),
        this.createItem('1 - 2 weeks', Filters.Range(key, [5, 10])),
        this.createItem('2 - 4 weeks', Filters.Range(key, [10, 21])),
        this.createItem('> 4 weeks', Filters.Range(key, [21, Number.MAX_VALUE]))
      ]
    });
  }

  renderInterventionsColumn() {
    return (
      <div className="column interventions-column">
        {this.renderTable({
          title: 'Services',
          items: this.serviceItems(),
          limit: 3
        })}
        {this.renderTable({
          title: 'Summer',
          items: this.summerItems()
        })}
        {this.renderTable({
          title: 'Notes',
          items: this.mergedNoteItems(),
          limit: 3
        })}
        {this.renderSimpleTable('Program', 'program_assigned', { limit: 3 })}
        {this.renderSimpleTable('Homeroom', 'homeroom_name', {
          limit: 3,
          students: this.props.students // these items won't be static
        })}
      </div>
    );
  }

  renderGradeTable() {
    const key = 'grade';
    const uniqueValues = _.compact(_.uniq(_.map(this.props.allStudents, key)));
    const items = uniqueValues.map(value => {
      return this.createItem(value, Filters.Equal(key, value));
    });
    const sortedItems = _.sortBy(items, function(item) {
      if (item.caption === 'TK') return -40;
      if (item.caption === 'PPK') return -30;
      if (item.caption === 'PK') return -20;
      if (item.caption === 'KF') return -10;
      return parseFloat(item.caption);
    });

    return this.renderTable({
      title: 'Grade',
      items: sortedItems,
      limit: 3
    });
  }

  renderGradeColumn() {
    return (
      <div className="column grades-column pad-column-right">
        {this.renderGradeTable()}
        {shouldDisplayHouse(this.props.school) && this.renderSimpleTable('House', 'house', { limit: 4})}
        {shouldDisplayCounselor(this.props.school) && this.renderSimpleTable('Counselor', 'counselor', { limit: 3})}
        {this.renderSimpleTable('Gender', 'gender', {})}
        {this.renderSimpleTable('Race', 'race', { limit: 3})}
        <FixedTable
          onFilterToggled={this.props.onFilterToggled}
          filters={this.props.filters}
          title="Hispanic/Latino"
          items={[
            this.createItem('Yes', Filters.Equal('hispanic_latino', true)),
            this.createItem('No', Filters.Equal('hispanic_latino', false)),
            this.createItem('None', Filters.Equal('hispanic_latino', null)),
          ]} />
      </div>
    );
  }

  renderYearsEnrolled() {
    const {nowFn} = this.context;
    const {allStudents} = this.props;
    const registrationDates = _.compact(allStudents.map(s => s.registration_date));

    if (registrationDates.length === 0) return null;

    const dateToday = nowFn().toDate();
    const uniqueValues =_.uniq(registrationDates.map(regDate => {
      return Math.floor((dateToday - new Date(regDate)) / (1000 * 60 * 60 * 24 * 365));
    }));

    const items = uniqueValues.map(value => {
      return this.createItem(value, Filters.YearsEnrolled(value));
    });

    const sortedItems = _.sortBy(items, function(item) { return parseFloat(item.caption); });

    return this.renderTable({
      title: 'Years enrolled',
      items: sortedItems,
      limit: 3
    });
  }

  renderSimpleTable(title, key, props = {}) {
    const uniqueValues = _.uniq(_.map(props.students || this.props.allStudents, key));
    const items = this.createItemsFromValues(key, uniqueValues);
    return this.renderTable({
      ...props,
      title: title,
      items: items
    });
  }

  renderTable(tableProps = {}) {
    const props = {
      ...tableProps,
      filters: this.props.filters,
      onFilterToggled: this.props.onFilterToggled
    };
    return <CollapsableTable {...props} />;
  }
}
SlicePanels.contextTypes = {
  nowFn: PropTypes.func.isRequired
};
SlicePanels.propTypes = {
  districtKey: PropTypes.string.isRequired,
  filters: PropTypes.arrayOf(PropTypes.object).isRequired,
  students: PropTypes.arrayOf(PropTypes.object).isRequired,
  allStudents: PropTypes.arrayOf(PropTypes.object).isRequired,
  school: PropTypes.object.isRequired,
  serviceTypesIndex: PropTypes.object.isRequired,
  onFilterToggled: PropTypes.func.isRequired
};
