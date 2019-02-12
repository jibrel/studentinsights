import PropTypes from 'prop-types';
import React from 'react';
import Card from '../components/Card';
import {isHomeroomMeaningful} from '../helpers/PerDistrict';
import Homeroom from '../components/Homeroom';
import Educator from '../components/Educator';
import {gradeText} from '../helpers/gradeText';


// Render a card in the feed for an EventNote
// Pure UI, like a template.
export default class FeedCardFrame extends React.Component {
  render() {
    const {style, student, byEl, whereEl, whenEl, children, iconsEl, badgesEl} = this.props;
    const {homeroom, school} = student;
    const shouldShowHomeroom = homeroom && school && isHomeroomMeaningful(school.school_type);
    return (
      <Card className="FeedCardFrame" style={style}>
        <div style={styles.header}>
          <div style={styles.studentHeader}>
            <div>
              <a style={styles.person} href={`/students/${student.id}`}>{student.first_name} {student.last_name}</a>
            </div>
            <div>{gradeText(student.grade)}</div>
            <div>
              {shouldShowHomeroom && <Homeroom
                id={homeroom.id}
                name={homeroom.name}
                educator={homeroom.educator} />}
            </div>
          </div>
          <div style={styles.by}>
            <div>{byEl}</div>
            <div>{whereEl}</div>
            <div>{whenEl}</div>
          </div>
        </div>
        <div style={styles.body}>
          {children}
        </div>
        <div className="FeedCardFrame-footer" style={styles.footer}>
          {/* so flex layout stays the same, regardless */}
          {iconsEl || <div />}
          {badgesEl || <div />}
        </div>
      </Card>
    );
  }
}
FeedCardFrame.contextTypes = {
  nowFn: PropTypes.func.isRequired
};
FeedCardFrame.propTypes = {
  student: PropTypes.shape({
    id: PropTypes.number.isRequired,
    first_name: PropTypes.string.isRequired,
    last_name: PropTypes.string.isRequired,
    grade: PropTypes.string.isRequired,
    house: PropTypes.string,
    school: PropTypes.shape({
      local_id: PropTypes.string.isRequired,
      school_type: PropTypes.string.isRequired
    }),
    homeroom: PropTypes.shape({
      id: PropTypes.number.isRequired,
      name: PropTypes.string.isRequired,
      educator: PropTypes.object
    })
  }).isRequired,
  children: PropTypes.node.isRequired,
  byEl: PropTypes.node,
  whereEl: PropTypes.node,
  whenEl: PropTypes.node,
  badgesEl: PropTypes.node,
  iconsEl: PropTypes.node,
  style: PropTypes.object
};


const styles = {
  header: {
    display: 'flex',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start'
  },
  studentHeader: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-start',
    justifyContent: 'flex-start'
  },
  body: {
    marginBottom: 20,
    marginTop: 20
  },
  by: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-end'
  },
  footer: {
    display: 'flex',
    justifyContent: 'space-between',
    marginBottom: 5
  },
  person: {
    fontWeight: 'bold'
  }
};


export function ByEducator({educator}) {
  return (
    <div>
      <span>by </span>
      <Educator
        style={styles.person}
        educator={educator} />
    </div>
  );
}
ByEducator.propTypes = {
  educator: PropTypes.object.isRequired
};
