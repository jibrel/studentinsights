import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import * as InsightsPropTypes from '../helpers/InsightsPropTypes';
import SectionHeading from '../components/SectionHeading';
import LightHelpBubble from './LightHelpBubble';
import NotesList from './NotesList';
import TakeNotes from './TakeNotes';
import TakeNotesTakeTwo from './TakeNotesTakeTwo';


/*
The bottom region of the page, showing notes about the student, services
they are receiving, and allowing users to enter new information about
these as well.
*/
export default class LightNotesDetails extends React.Component {

  constructor(props){
    super(props);
    this.state = {
      isTakingNotes: false,
      isAuthoring: false,
    };

    this.onStartAuthoring = this.onStartAuthoring.bind(this);
    this.onClickTakeNotes = this.onClickTakeNotes.bind(this);
    this.onClickSaveNotes = this.onClickSaveNotes.bind(this);
    this.onCancelNotes = this.onCancelNotes.bind(this);
  }

  isTakingNotes() {
    return (
      this.state.isTakingNotes ||
      this.props.requests.saveNote !== null ||
      this.props.noteInProgressText.length > 0 ||
      this.props.noteInProgressAttachmentUrls.length > 0
    );
  }

  onStartAuthoring() {
    this.setState({isAuthoring: true});
  }

  onClickTakeNotes(event) {
    this.setState({ isTakingNotes: true });
  }

  onCancelNotes(event) {
    this.setState({ isTakingNotes: false });
  }

  onClickSaveNotes(eventNoteParams, event) {
    this.props.actions.onClickSaveNotes(eventNoteParams);
    this.setState({ isTakingNotes: false });
  }

  render() {
    const {student, title, currentEducator} = this.props;
    const {isAuthoring} = this.state;
    const isTakeTwoEnabled = (window.location.search.indexOf('taketwowrite') !== -1);

    return (
      <div className="LightNotesDetails" style={styles.notesContainer}>
        {<SectionHeading titleStyle={{display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
          <div style={{display: 'flex', alignItems: 'center', padding: 2}}>
            <span>{title} for {student.first_name}</span>
            <LightHelpBubble
              title={this.props.helpTitle}
              content={this.props.helpContent} />
          </div>
          <div>
            {!this.isTakingNotes() && this.renderTakeNotesButton()}
            {!isTakeTwoEnabled && isAuthoring && (
              <button
                className="btn take-notes"
                style={{display: 'inline-block', margin: 0}}
                onClick={this.onStartAuthoring}>
                <span><span style={{fontWeight: 'bold', paddingRight: 5}}>+</span><span>v2</span></span>
              </button>
            )}
          </div>
        </SectionHeading>}
        <div>
          {isTakeTwoEnabled && isAuthoring && (
            <TakeNotesTakeTwo
              style={{marginTop: 20, marginBottom: 20}}
              educator={currentEducator}
              student={student}
            />
          )}
          {this.isTakingNotes() && this.renderTakeNotesDialog()}
          <NotesList
            currentEducatorId={currentEducator.id}
            feed={this.props.feed}
            canUserAccessRestrictedNotes={currentEducator.can_view_restricted_notes}
            educatorsIndex={this.props.educatorsIndex}
            onSaveNote={this.onClickSaveNotes}
            onEventNoteAttachmentDeleted={this.props.actions.onDeleteEventNoteAttachment} />
        </div>
      </div>
    );
  }

  renderTakeNotesDialog() {
    const {
      currentEducator,
      noteInProgressText,
      noteInProgressType,
      noteInProgressAttachmentUrls,
      actions,
      requests
    } = this.props;

    return (
      <TakeNotes
        // TODO(kr) thread through
        nowMoment={moment.utc()}
        currentEducator={currentEducator}
        onSave={this.onClickSaveNotes}
        onCancel={this.onCancelNotes}
        requestState={requests.saveNote}
        noteInProgressText={noteInProgressText}
        noteInProgressType={noteInProgressType}
        noteInProgressAttachmentUrls={noteInProgressAttachmentUrls}
        onClickNoteType={actions.onClickNoteType}
        onChangeNoteInProgressText={actions.onChangeNoteInProgressText}
        onChangeAttachmentUrl={actions.onChangeAttachmentUrl}
        showRestrictedCheckbox={currentEducator.can_view_restricted_notes}
      />
    );
  }

  renderTakeNotesButton() {
    return (
      <button
        className="btn take-notes"
        style={{display: 'inline-block', margin: 0}}
        onClick={this.onClickTakeNotes}>
        <span><span style={{fontWeight: 'bold', paddingRight: 5}}>+</span><span>note</span></span>
      </button>
    );
  }
}

LightNotesDetails.propTypes = {
  student: PropTypes.object.isRequired,
  educatorsIndex: PropTypes.object.isRequired,
  currentEducator: PropTypes.shape({
    can_view_restricted_notes: PropTypes.bool.isRequired
  }).isRequired,
  actions: PropTypes.shape({
    onClickSaveNotes: PropTypes.func.isRequired,
    onEventNoteAttachmentDeleted: PropTypes.func,
    onDeleteEventNoteAttachment: PropTypes.func,
    onChangeNoteInProgressText: PropTypes.func.isRequired,
    onClickNoteType: PropTypes.func.isRequired,
    onChangeAttachmentUrl: PropTypes.func.isRequired,
  }),
  feed: InsightsPropTypes.feed.isRequired,
  requests: PropTypes.object.isRequired,

  noteInProgressText: PropTypes.string.isRequired,
  noteInProgressType: PropTypes.number,
  noteInProgressAttachmentUrls: PropTypes.arrayOf(
    PropTypes.string
  ).isRequired,

  title: PropTypes.string.isRequired,
  helpContent: PropTypes.node.isRequired,
  helpTitle: PropTypes.string.isRequired,
};


const styles = {
  notesContainer: {
    width: '50%',
    marginRight: 20
  }
};
