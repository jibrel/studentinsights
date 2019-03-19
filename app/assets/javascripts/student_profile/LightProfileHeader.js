import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import {AutoSizer} from 'react-virtualized';
import * as Routes from '../helpers/Routes';
import {
  hasStudentPhotos,
  supportsHouse,
  isHomeroomMeaningful
} from '../helpers/PerDistrict';
import HelpBubble, {
  modalFromLeft,
  modalFromRight,
  modalFullScreenWithVerticalScroll
} from '../components/HelpBubble';
import StudentPhoto from '../components/StudentPhoto';
import {TeamIcon} from '../components/Team';
import Homeroom from '../components/Homeroom';
import LightCarousel from './LightCarousel';
import ProfilePdfDialog from './ProfilePdfDialog';
import LightHeaderSupportBits from './LightHeaderSupportBits';


/*
UI component for top-line information like the student's name, school,
photo and classroom.  Also includes a carousel of humanizing quotes about
the student, and some buttons for exporting, etc.
*/
export default class LightProfileHeader extends React.Component {
  hasPhoto() {
    const {districtKey} = this.context;
    const {student} = this.props;
    const shouldShowPhoto = hasStudentPhotos(districtKey);
    return (shouldShowPhoto && student.has_photo);
  }

  render() {
    const {style} = this.props;
    const hasPhoto = this.hasPhoto();
    const firstColumnFlex = (hasPhoto) ? 1 : 0;
    const secondColumnFlex = (hasPhoto) ? 2 : 3;
    return (
      <div className="LightProfileHeader" style={{...styles.root, style}}>
        <div style={{flex: firstColumnFlex, display: 'flex', flexDirection: 'row'}}>
          {this.renderStudentPhotoOrNull()}
        </div>
        <div style={{flex: secondColumnFlex, display: 'flex', flexDirection: 'row'}}>
          {this.renderOverview()}
        </div>
        <div style={{flex: 2, display: 'flex', flexDirection: 'row', marginTop: 10}}>
          {this.renderGlance()}
          {this.renderButtons()}
        </div>
      </div>
    );
  }

  renderStudentPhotoOrNull() {
    const {student, teams} = this.props;
    if (!this.hasPhoto()) return null;
    
    // The teams badges hang over the bottom
    return (
      <div style={{flex: 1, marginLeft: 10, position: 'relative'}}>
        <AutoSizer>
          {({width, height}) => (
            <StudentPhoto
              style={{...styles.photoEl, maxWidth: width, maxHeight: height}}
              student={student} />
          )}
        </AutoSizer>
        <div style={{position: 'absolute', bottom: -30, left: 5}}>
          {teams.map(team => (
            <TeamIcon
              key={team.activity_text}
              style={{fontSize: 20}}
              team={team}
            />
          ))}
        </div>
      </div>
    );
  }

  renderOverview() {
    const {student} = this.props;
    return (
      <div style={styles.overview}>
        <div style={styles.overviewColumn}>
          <a href={Routes.studentProfile(student.id)} style={styles.nameTitle}>
            {student.first_name + ' ' + student.last_name}
          </a>
          {this.renderHomeroomOrEnrollmentStatus()}
          {this.renderHouseAndGrade()}
          <div style={styles.subtitleItem}>
            {student.school_name}
          </div>
        </div>
        <div style={styles.infoBitsRow}>
          <div style={styles.infoBitsBox}>
            <div style={{marginTop: 20}}>{this.renderAge()}</div>
            {this.renderDateOfBirth()}
            <div style={styles.subtitleItem}>{student.home_language} at home</div>
            {this.renderContactIcon()}
          </div>
          <div style={styles.infoBitsBox}>
            {this.renderSupportBits()}
          </div>
          {this.hasPhoto() ? null : <div style={{flex: 1}} />}
        </div>
      </div>
    );
  }

  renderHouseAndGrade() {
    const {districtKey} = this.context;
    const {student} = this.props;
    const showHouse = (
      supportsHouse(districtKey) &&
      student.house
    );

    return (
      <div style={styles.subtitleItem}>
        {'Grade ' + student.grade}
        {showHouse && `, ${student.house} house`}
      </div>
    );
  }

  renderHomeroomOrEnrollmentStatus() {
    const {student} =  this.props;

    // Not enrolled
    if (student.enrollment_status !== 'Active') {
      return (
        <span style={styles.subtitleItem}>
          {student.enrollment_status}
        </span>
      );
    }

    // No homeroom set
    if (!student.homeroom) {
      return <span style={styles.subtitleItem}>No homeroom</span>;
    }

    // Render as link or plain text
    // (HS homeroom doesn't mean anything, and authorization
    // rules around whether they can link to the homeroom page
    // are more complex).
    const {id, name, educator} = student.homeroom;
    return (
      <Homeroom
        style={styles.subtitleItem}
        disableLink={!isHomeroomMeaningful(student.school_type)}
        id={id}
        name={name}
        educator={educator}
      />
    );
  }

  renderDateOfBirth () {
    const student =  this.props.student;
    const dateOfBirth = student.date_of_birth;
    if (!dateOfBirth) return null;

    const momentDOB = moment.utc(dateOfBirth);
    return <div style={styles.subtitleItem}>{momentDOB.format('M/D/YYYY')}</div>;
  }

  renderAge() {
    const student =  this.props.student;
    const dateOfBirth = student.date_of_birth;
    if (!dateOfBirth) return null;

    const {nowFn} = this.context;
    const nowMoment = nowFn();
    const momentDOB = moment.utc(dateOfBirth);
    return <div style={styles.subtitleItem}>{nowMoment.clone().diff(momentDOB, 'years')} years old</div>;
  }

  renderContactIcon () {
    return (
      <HelpBubble
        style={{marginLeft: 0, display: 'inline-block'}}
        linkStyle={styles.subtitleItem}
        teaser="Family contacts"
        modalStyle={modalFromLeft}
        title="Family contacts"
        content={this.renderContactInformationDialog()} />
    );
  }

  renderContactInformationDialog(){
    const {student} = this.props;
    return (
      <span>
        <span style={styles.contactItem}>
          {student.student_address}
        </span>
        <span style={styles.contactItem}>
          {student.primary_phone}
        </span>
        <span style={styles.contactItem}>
          <a href={'mailto:'+ student.primary_email}>{student.primary_email}</a>
        </span>
      </span>
    );
  }


  renderSupportBits() {
    const {
      currentEducator,
      student,
      iepDocument,
      access,
      teams,
      activeServices,
      edPlans
    } = this.props;
    return (
      <LightHeaderSupportBits
        educatorLabels={currentEducator.labels}
        student={student}
        access={access}
        teams={teams}
        iepDocument={iepDocument}
        activeServices={activeServices}
        edPlans={edPlans}
      />
    );
  }

  renderButtons() {
    return (
      <div style={{marginLeft: 10, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end'}}>
        {this.renderProfilePdfButton()}
        {this.renderFullCaseHistoryButton()}
      </div>
    );
  }

  renderProfilePdfButton() {
    const {student, currentEducator} = this.props;
    return (
      <HelpBubble
        style={{marginLeft: 0}}
        modalStyle={modalFromRight}
        teaser={
          <svg style={styles.svgIcon} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M19 8H5c-1.66 0-3 1.34-3 3v6h4v4h12v-4h4v-6c0-1.66-1.34-3-3-3zm-3 11H8v-5h8v5zm3-7c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1zm-1-9H6v4h12V3z"/>
            <path d="M0 0h24v24H0z" fill="none"/>
          </svg>
        }
        tooltip="Print PDF"
        title="Print PDF"
        content={
          <ProfilePdfDialog
            studentId={student.id}
            allowRestrictedNotes={currentEducator.can_view_restricted_notes}
            style={{backgroundColor: 'white'}}
          />
        }
      />
    );
  }

  renderFullCaseHistoryButton() {
    const {renderFullCaseHistory} = this.props;
    return (
      <HelpBubble
        style={{marginLeft: 0}}
        modalStyle={modalFullScreenWithVerticalScroll}
        teaser={
          <svg style={styles.svgIcon} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
            <path d="M14 17H4v2h10v-2zm6-8H4v2h16V9zM4 15h16v-2H4v2zM4 5v2h16V5H4z"/>
            <path d="M0 0h24v24H0z" fill="none"/>
          </svg>
        }
        tooltip="List all data points"
        title="List all data points"
        content={renderFullCaseHistory()}
      />
    );
  }

  renderGlance() {
    const {profileInsights, student} = this.props;
    return (
      <div style={styles.carousel}>
        <LightCarousel
          profileInsights={profileInsights}
          student={student}
        />
      </div>
    );
  }
}
LightProfileHeader.contextTypes = {
  nowFn: PropTypes.func.isRequired,
  districtKey: PropTypes.string.isRequired
};
LightProfileHeader.propTypes = {
  currentEducator: PropTypes.shape({
    can_view_restricted_notes: PropTypes.bool.isRequired,
    labels: PropTypes.arrayOf(PropTypes.string).isRequired
  }),
  student: PropTypes.shape({
    id: PropTypes.number.isRequired,
    first_name: PropTypes.string.isRequired,
    last_name: PropTypes.string.isRequired,
    grade: PropTypes.string,
    disability: PropTypes.string,
    sped_placement: PropTypes.string,
    plan_504: PropTypes.string,
    limited_english_proficiency: PropTypes.string,
    ell_entry_date: PropTypes.string,
    ell_transition_date: PropTypes.string,
    enrollment_status: PropTypes.string,
    home_language: PropTypes.string,
    date_of_birth: PropTypes.string,
    student_address: PropTypes.string,
    primary_phone: PropTypes.string,
    primary_email: PropTypes.string,
    house: PropTypes.string,
    counselor: PropTypes.string,
    sped_liaison: PropTypes.string,
    school_name: PropTypes.string,
    school_type: PropTypes.string,
    school_local_id: PropTypes.string,
    homeroom: PropTypes.shape({
      id: PropTypes.number.isRequired,
      name: PropTypes.string.isRequired,
      educator: PropTypes.object
    }),
    has_photo: PropTypes.bool
  }).isRequired,
  iepDocument: PropTypes.object,
  activeServices: PropTypes.array.isRequired,
  access: PropTypes.object,
  teams: PropTypes.array.isRequired,
  profileInsights: PropTypes.array.isRequired,
  edPlans: PropTypes.arrayOf(PropTypes.object).isRequired,
  renderFullCaseHistory: PropTypes.func.isRequired,
  style: PropTypes.object
};

const styles = {
  root: {
    display: 'flex',
    height: 220,
    fontSize: 14,
    padding: 20,
    marginBottom: 20
  },

  overview: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'space-between',
    flex: 2
  },
  photo: {
    paddingLeft: 10,
    paddingRight: 20
  },
  photoEl: {
    borderRadius: 2,
    border: '1px solid #ccc',
    marginRight: 20
  },
  nameTitle: {
    fontWeight: 'bold',
    marginRight: 5,
    fontSize: 20
  },
  infoBitsRow: {
    display: 'flex',
    flexDirection: 'row'
  },
  infoBitsBox: {
    flex: 1,
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'flex-end'
  },
  overviewColumn: {
    display: 'flex',
    flexDirection: 'column',
    flex: 1
  },
  subtitleItem: {
    display: 'inline-block',
    fontSize: 14
  },
  contactItem: {
    padding: 6,
    display: 'flex'
  },
  svgIcon: {
    fill: "#3177c9",
    opacity: 0.5
  },
  carousel: {
    flex: 1,
    display: 'flex'
  }
};

