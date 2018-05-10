import React from 'react';
import School from '../components/School';
import Educator from '../components/Educator';
import GenericLoader from '../components/GenericLoader';
import SectionHeading from '../components/SectionHeading';
import tableStyles from '../components/tableStyles';
import {toMomentFromTime} from '../helpers/toMoment';
import {gradeText} from '../helpers/gradeText';
import {fetchAllWorkspaces} from './api';


// Show users their class lists.  More useful for principals, building admin,
// or ELL/SPED teachers than classroom teachers (who are typically
// making a single list).
export default class ClassListsViewPage extends React.Component {
  render() {
    return (
      <div className="ClassListsViewPage">
        <GenericLoader
          style={styles.root}
          promiseFn={fetchAllWorkspaces}
          render={json => <ClassListsViewPageView {...json} />} />
      </div>
    );
  }
}


// View component
export class ClassListsViewPageView extends React.Component {
  render() {
    return (
      <div>
        <SectionHeading>Class lists</SectionHeading>
        {this.renderTable()}
      </div>
    );
  }

  renderTable() {
    const {workspaces} = this.props;
    if (workspaces.length === 0) return <div>None!</div>;

    return (
      <table style={tableStyles.table}>
        <thead>
          <tr>
            <th style={tableStyles.headerCell}>School</th>
            <th style={tableStyles.headerCell}>Grade next year</th>
            <th style={tableStyles.headerCell}>Owner</th>
            <th style={tableStyles.headerCell}>Created on</th>
            <th style={tableStyles.headerCell}>Revisions</th>
            <th style={tableStyles.headerCell}>Workspace</th>
            <th style={tableStyles.headerCell} />
          </tr>
        </thead>
        <tbody>{workspaces.map(workspace => {
          const classList = workspace.class_list;
          return (
            <tr key={workspace.workspace_id}>
              <td style={tableStyles.cell}><School {...classList.school} /></td>
              <td style={tableStyles.cell}>{gradeText(classList.grade_level_next_year)}</td>
              <td style={tableStyles.cell}><Educator educator={classList.created_by_educator} /></td>
              <td style={tableStyles.cell}>{toMomentFromTime(classList.created_at).format('dddd M/D')}</td>
              <td style={tableStyles.cell}>{workspace.revisions_count}</td>
              <td style={tableStyles.cell}><pre>{classList.workspace_id.slice(0, 4)}-{classList.id}</pre></td>
              <td style={tableStyles.cell}><a href={`/classlists/${classList.workspace_id}`}>open</a></td>
            </tr>
          );
        })}</tbody>
      </table>
    );
  }
}
ClassListsViewPageView.propTypes = {
  workspaces: React.PropTypes.arrayOf(React.PropTypes.shape({
    workspace_id: React.PropTypes.string.isRequired,
    revisions_count: React.PropTypes.number.isRequired,
    class_list: React.PropTypes.shape({
      id: React.PropTypes.number.isRequired,
      workspace_id: React.PropTypes.string.isRequired,
      grade_level_next_year: React.PropTypes.string.isRequired,
      created_at: React.PropTypes.string.isRequired,
      updated_at: React.PropTypes.string.isRequired,
      submitted: React.PropTypes.bool.isRequired,
      created_by_educator: React.PropTypes.object.isRequired,
      school: React.PropTypes.object.isRequired,
    }).isRequired
  })).isRequired
};


const styles = {
  root: {
    padding: 10
  }  
};
