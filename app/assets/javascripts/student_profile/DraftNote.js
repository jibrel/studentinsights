import _ from 'lodash';
import React from 'react';
import PropTypes from 'prop-types';
import {takeNotesChoices} from '../helpers/PerDistrict';
import {eventNoteTypeText} from '../helpers/eventNoteType';
import Educator from '../components/Educator';
import FeedCardFrame from '../feed/FeedCardFrame';


/*
Pure UI form for taking notes about an event, tracking its own local state
and submitting it to prop callbacks.
*/
export default class DraftNote extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      isRestricted: false,
      text: '',
      eventNoteTypeId: null
    };
    this.onRestrictedToggled = this.onRestrictedToggled.bind(this);
    this.onClickCancel = this.onClickCancel.bind(this);
    this.onClickSave = this.onClickSave.bind(this);
    this.onChangeText = this.onChangeText.bind(this);
    this.onClickNoteType = this.onClickNoteType.bind(this);
  }

  // Focus on note-taking text area when it first appears.
  componentDidMount(prevProps, prevState) {
    this.textareaRef.focus();
  }

  wrapUrlInObject(urlString) {
    return { url: urlString };
  }

  disabledSaveButton() {
    const {text, eventNoteTypeId} = this.state;

    return (text === '' || eventNoteTypeId === null);
  }

  onChangeText(e) {
    this.setState({text: e.target.value});
  }

  onClickNoteType(eventNoteTypeId) {
    this.setState({eventNoteTypeId});
  }

  onRestrictedToggled(e) {
    const {isRestricted} = this.state;
    this.setState({isRestricted: !isRestricted});
  }

  onClickCancel(event) {
    this.props.onCancel();
  }

  onClickSave(event) {
    const {onSave, showRestrictedCheckbox} = this.props;
    const {isRestricted, text, eventNoteTypeId} = this.state;

    const params = {
      eventNoteTypeId,
      text,
      ...(showRestrictedCheckbox ? {isRestricted} : {})
    };

    onSave(params);
  }

  render() {
    const {
      style,
      student,
      currentEducator
    } = this.props;

    return (
      <div className="DraftNote" style={{...styles.root, ...style}}>
        <FeedCardFrame
          style={style}
          student={student}
          byEl={
            <div>
              <span>by </span>
              <Educator
                style={styles.person}
                educator={currentEducator} />
            </div>
          }
          whenEl={'right now'}
          whereEl={null}
          badgesEl={null}
          iconsEl={this.renderIconsEl()}
        >
          {this.renderContent()}
        </FeedCardFrame>
      </div>
    );
  }

  renderContent() {
    const {showRestrictedCheckbox} = this.props;
    const {text} = this.state;

    return (
      <div style={styles.content}>
        <textarea
          className="DraftNote-textarea"
          rows={10}
          style={styles.textarea}
          ref={ref => this.textareaRef = ref}
          value={text}
          onChange={this.onChangeText} />
        {showRestrictedCheckbox &&
          <div>
            <div style={{ marginBottom: 5, marginTop: 20 }}>
              Restrict access?
            </div>
            <label style={{ marginLeft: 10, color: 'black', cursor: 'pointer' }}>
              <input type="checkbox" onClick={this.onRestrictedToggled} />
              <span style={{paddingLeft: 5}}>Yes, note contains private or sensitive personal information</span>
            </label>
          </div>
        }
        <div style={{ marginBottom: 5, marginTop: 20 }}>
          What are these notes from?
        </div>
        {this.renderNoteButtonsPerDistrict()}
        <button
          style={{
            marginTop: 20,
            background: (this.disabledSaveButton()) ? '#ccc' : undefined
          }}
          disabled={this.disabledSaveButton()}
          className="btn save"
          onClick={this.onClickSave}>
          Save notes
        </button>
        <button
          className="btn cancel"
          style={styles.cancelDraftNoteButton}
          onClick={this.onClickCancel}>
          Cancel
        </button>
      </div>
    );
  }

  renderNoteButtonsPerDistrict() {
    const {districtKey} = this.context;
    const {leftEventNoteTypeIds, rightEventNoteTypeIds} = takeNotesChoices(districtKey);
    return (
      <div style={{ display: 'flex' }}>
        <div style={{ flex: 1 }}>
          {leftEventNoteTypeIds.map(this.renderNoteButton, this)}
        </div>
        <div style={{ flex: 1 }}>
          {rightEventNoteTypeIds.map(this.renderNoteButton, this)}
        </div>
      </div>
    );
  }

  renderNoteButton(eventNoteTypeId) {
    return (
      <button
        key={eventNoteTypeId}
        className="btn note-type"
        onClick={this.onClickNoteType.bind(this, eventNoteTypeId)}
        tabIndex={-1}
        name={eventNoteTypeId}
        style={{
          ...styles.serviceButton,
          background: '#eee',
          outline: 0,
          border: (eventNoteTypeId === this.state.eventNoteTypeId)
            ? '4px solid rgba(49, 119, 201, 0.75)'
            : '4px solid white'
        }}>
        {eventNoteTypeText(eventNoteTypeId)}
      </button>
    );
  }

  renderIconsEl() {
    const {requestState} = this.props;
    if (requestState === 'pending') return <span>Saving...</span>;
    if (requestState === 'error') return <span>Try again!</span>;
    return null;
  }
}
DraftNote.contextTypes = {
  districtKey: PropTypes.string.isRequired,
  nowFn: PropTypes.func.isRequired
};
DraftNote.propTypes = {
  student: PropTypes.object.isRequired,
  style: PropTypes.object,
  onSave: PropTypes.func.isRequired,
  onCancel: PropTypes.func.isRequired,
  currentEducator: PropTypes.object.isRequired,
  requestState: PropTypes.string, // or null
  showRestrictedCheckbox: PropTypes.bool
};
DraftNote.defaultProps = {
  showRestrictedCheckbox: false
};


const styles = {
  root: {
    marginTop: 10
  },
  content: {
    padding: 10,
  },
  textarea: {
    fontSize: 14,
    border: '1px solid #eee',
    width: '100%' //overriding strange global CSS, should cleanup
  },
  input: {
    fontSize: 14,
    border: '1px solid #eee',
    width: '100%'
  },
  cancelDraftNoteButton: { // overidding CSS
    color: 'black',
    background: '#eee',
    marginLeft: 10,
    marginRight: 10
  },
  serviceButton: {
    background: '#eee', // override CSS
    color: 'black',
    // shrinking:
    minWidth: '14em',
    fontSize: 12,
    marginRight: '1em',
    padding: 8
  }
};
