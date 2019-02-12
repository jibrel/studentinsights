import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import Educator from '../components/Educator';
import NoteText from '../components/NoteText';
import EditableNoteText from '../components/EditableNoteText';
import * as Routes from '../helpers/Routes';
import {formatEducatorName} from '../helpers/educatorName';
import RestrictedNotePresence from './RestrictedNotePresence';


// This renders a single card for a Note of any type.
export default class NoteCard extends React.Component {
  constructor(props) {
    super(props);

    this.onBlurText = this.onBlurText.bind(this);
  }

  educator() {
    const {educatorId, educatorsIndex} = this.props;
    if (!educatorId) return null;
    return educatorsIndex[educatorId];
  }

  // No feedback, fire and forget
  onDeleteAttachmentClicked(eventNoteAttachmentId) {
    this.props.onEventNoteAttachmentDeleted(eventNoteAttachmentId);
  }

  onBlurText(textValue) {
    if (!this.props.onSave) return;

    this.props.onSave({
      id: this.props.eventNoteId,
      eventNoteTypeId: this.props.eventNoteTypeId,
      text: textValue
    });
  }

  render() {
    const {includeStudentPanel} = this.props;
    const educator = this.educator();
    return (
      <div className="wrapper" style={styles.wrapper}>
        {includeStudentPanel && this.renderStudentCard()}
        <div className="NoteCard" style={styles.note}>
          <div style={styles.titleLine}>
            <span className="date" style={styles.date}>
              {this.props.noteMoment.format('MMMM D, YYYY')}
            </span>
            {this.props.badge}
            {educator && (
              <span style={styles.educator}>
                <Educator educator={educator} />
              </span>
            )}
          </div>
          {this.renderNoteSubstanceOrRedaction()}
          {this.renderAttachmentUrls()}
        </div>
      </div>        
    );
  }

  // For restricted notes, show a message and allow switching to another
  // component that allows viewing and editing.
  // Otherwise, show the substance of the note.
  renderNoteSubstanceOrRedaction() {
    const {showRestrictedNoteRedaction} = this.props;
    return (showRestrictedNoteRedaction)
      ? this.renderRestrictedNoteRedaction()
      : this.renderText();
  }

  // The student name may or not be present.
  renderRestrictedNoteRedaction() {
    const {student, urlForRestrictedNoteContent} = this.props;
    const educatorName = formatEducatorName(this.educator());
    const educatorFirstNameOrEmail = educatorName.indexOf(' ') !== -1
      ? educatorName.split(' ')[0]
      : educatorName;
    
    return (
      <RestrictedNotePresence
        showRestrictedLabel={true}
        studentFirstName={student ? student.first_name : null}
        educatorName={educatorFirstNameOrEmail}
        urlForRestrictedNoteContent={urlForRestrictedNoteContent}
      />
    );
  }

  // If an onSave callback is provided, the text is editable.
  // This is for older interventions that are read-only 
  // because of changes to the server data model.
  renderText() {
    const {onSave, text, numberOfRevisions} = this.props;
    if (onSave) {
      return (
        <EditableNoteText
          text={text}
          numberOfRevisions={numberOfRevisions}
          onBlurText={this.onBlurText} />
      );
    }
    
    return <NoteText text={text} />;        
  }

  renderAttachmentUrls() {
    const {showRestrictedNoteRedaction, attachments} = this.props;
    if (showRestrictedNoteRedaction) return null;
    
    return attachments.map(attachment => {
      return (
        <div key={attachment.id}>
          <p style={{
            display: 'flex',
            alignItems: 'center',
            marginTop: 10
          }}>
            <span>link:</span>
            <a
              href={attachment.url}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                display: 'inline-block',
                marginLeft: 10,
                marginRight: 10,
                overflow: 'hidden',
                textOverflow: 'ellipsis'
              }}>
              {attachment.url}
            </a>
            {this.renderRemoveAttachmentLink(attachment)}
          </p>
        </div>
      );
    });
  }

  // Can only remove attachments if callback is provided
  renderRemoveAttachmentLink(attachment) {
    if (!this.props.onEventNoteAttachmentDeleted) return null;

    return (
      <a
        onClick={this.onDeleteAttachmentClicked.bind(this, attachment.id)}
        style={{
          display: 'inline-block',
          marginLeft: 10
        }}>
        (remove)
      </a>
    );
  }

  renderHomeroomOrGrade(student) {
    if (student.grade < 9) {
      if (student.homeroom_id) {
        return (
          <p><a
            className="homeroom-link"
            href={Routes.homeroom(student.homeroom_id)}>
            {'Homeroom ' + student.homeroom_name}
          </a></p>
        );
      }
      else {
        return (
          <p>No Homeroom</p>
        );
      }
    }
    else {
      return (
        <p>{student.grade}th Grade</p>
      );
    }
  }

  renderSchool(student) {
    if (student.school_id) {
      return (
        <p><a
          className="school-link"
          href={Routes.school(student.school_id)}>
          {student.school_name}
        </a></p>
      );
    }
    else {
      return (
        <p>No School</p>
      );
    }
  }

  renderStudentCard() {
    const {student} = this.props;
    if (student) {
      return (
        <div className="studentCard" style={styles.studentCard}>
          <p><a style={styles.studentName} href={Routes.studentProfile(student.id)}>
            {student.last_name}, {student.first_name}
          </a></p>
          {this.renderSchool(student)}
          {this.renderHomeroomOrGrade(student)}
        </div>
      );
    }
  }
}
NoteCard.propTypes = {
  attachments: PropTypes.array.isRequired,
  badge: PropTypes.element.isRequired,
  educatorId: PropTypes.number,
  educatorsIndex: PropTypes.object.isRequired,
  noteMoment: PropTypes.instanceOf(moment).isRequired,
  text: PropTypes.string.isRequired,

  // For editing eventNote only
  eventNoteId: PropTypes.number,
  eventNoteTypeId: PropTypes.number,
  numberOfRevisions: PropTypes.number,
  onEventNoteAttachmentDeleted: PropTypes.func,
  onSave: PropTypes.func,

  // Configuring for different uses
  showRestrictedNoteRedaction: PropTypes.bool,
  urlForRestrictedNoteContent: PropTypes.string,
  
  // For side panel for my notes page
  includeStudentPanel: PropTypes.bool,
  student: PropTypes.object
};
NoteCard.defaultProps = {
  numberOfRevisions: 0
};


const styles = {
  note: {
    border: '1px solid #eee',
    padding: 15,
    marginTop: 10,
    marginBottom: 10,
    width: '100%'
  },
  titleLine: {
    display: 'flex',
    justifyContent: 'space-between'
  },
  date: {
    display: 'inline-block',
    width: '11em',
    paddingRight: 10,
    fontWeight: 'bold'
  },
  educator: {
    paddingLeft: 5,
    display: 'inline-block'
  },
  studentCard: {
    border: '1px solid #eee',
    padding: 15,
    marginTop: 10,
    marginBottom: 10,
    width: '25%'
  },
  studentName: {
    fontSize: '18px',
    fontWeight: 'bold',
    color: '#3177c9',
    marginBottom: '5%'
  },
  wrapper: {
    display: 'flex'
  },
  restrictedNoteRedaction: {
    color: '#999'
  }
};