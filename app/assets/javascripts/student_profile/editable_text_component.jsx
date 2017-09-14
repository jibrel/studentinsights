(function () {
  window.shared || (window.shared = {});
  const Sanitize = window.Sanitize;

  const sanitize = new Sanitize({
    elements: ['br', 'div', 'p']
  });

  // Given a string of HTML, sanitize it by removing elements that are not
  // whitelisted.
  function htmlToSanitizedHTML(html) {
    const node = document.createElement('div');
    const newNode = document.createElement('div');

    node.innerHTML = html;
    const sanitizedDocumentFragment = sanitize.clean_node(node);

    while (sanitizedDocumentFragment.childNodes.length > 0) {
      newNode.appendChild(sanitizedDocumentFragment.childNodes[0]);
    }

    return newNode.innerHTML;
  }

  // Given a DOM node, attempt to transform it into plain text with reasonable
  // newlines.
  function domNodeToText(node) {
    let text = '';

    if (
      node.previousSibling
      && _(['BR', 'DIV', 'P']).contains(node.tagName)
    ) {
      text = '\n';
    }

    if (node.childNodes.length === 0) {
      text = text.concat(node.textContent);
    } else {
      for (let i = 0; i < node.childNodes.length; i++) {
        text = text.concat(domNodeToText(node.childNodes[i]));
      }
    }

    return text;
  }

  // Convert HTML to text. This will involve attempting to add expected
  // newlines.
  function htmlToText(html) {
    const node = document.createElement('div');

    node.innerHTML = html;

    return domNodeToText(node);
  }

  // Convert plain text to HTML. For our purposes, this just means replacing
  // newlines with `<br>` tags.
  function textToHTML(text) {
    let html = text || '';

    html = html.replace(/\n/g, '<br>');

    return html;
  }

  // Convert text, which possibly contains HTML-meaningful characters, into
  // sanitized HTML.
  function textToSanitizedHTML(text) {
    return textToHTML(_.escape(text));
  }

  // A contenteditable div is effectively a WYSIWYG editor, where the
  // content will be HTML markup generated by the browser as the user
  // edits the field. As such, we'll need to convert between the HTML
  // in the div and the text that is stored in the database. See
  // `textToSanitizedHTML` and `htmlToText` above.
  window.shared.EditableTextComponent = React.createClass({
    displayName: 'EditableTextComponent',

    propTypes: {
      text: React.PropTypes.string.isRequired,
      onBlurText: React.PropTypes.func.isRequired,
      className: React.PropTypes.string,
      style: React.PropTypes.object
    },

    getDefaultProps() {
      return {
        style: {}
      };
    },

    getInitialState() {
      return {
        text: this.props.text
      };
    },

    // Different user agents generate different HTML to achieve the same visual
    // rendering in contenteditable elements. In other words, `htmlToText` may
    // return the same plain text for different HTML strings, which means
    // `textToSanitizedHTML(htmlToText(html))` is not guaranteed to return `html`.
    // For our purposes, there's no need to normalize the HTML content between
    // page loads. Instead, we simply need to make sure that (1) the HTML is
    // sanitized, and (2) the HTML converted to plain text matches the next
    // state of the text.
    shouldComponentUpdate(nextProps, nextState) {
      const currentHTML = this.contentEditableEl.innerHTML;

      return currentHTML !== htmlToSanitizedHTML(currentHTML)
        || nextState.text !== htmlToText(currentHTML);
    },

    componentDidUpdate() {
      const expectedHTML = textToSanitizedHTML(this.state.text);

      if (
        this.contentEditableEl
        && expectedHTML !== this.contentEditableEl.innerHTML
      ) {
        this.contentEditableEl.innerHTML = expectedHTML;
      }
    },

    onModifyText() {
      const text = htmlToText(this.contentEditableEl.innerHTML);

      if (text !== this.lastText) {
        this.setState({ text });
        this.isDirty = true;
      }

      this.lastText = text;
    },

    onBlurText(event) {
      if (!this.isDirty) return null;

      this.props.onBlurText(this.state.text);

      this.isDirty = false;
    },

    render() {
      return (
        <div
          contentEditable
          className={this.props.className}
          style={this.props.style}
          ref={function (ref) { this.contentEditableEl = ref; }.bind(this)}
          dangerouslySetInnerHTML={{ __html: textToSanitizedHTML(this.state.text) }}
          onInput={this.onModifyText}
          // For IE compatibility.
          onKeyUp={this.onModifyText}
          onPaste={this.onModifyText}
          onBlur={this.onBlurText}
        />
      );
    },

  });
}());
