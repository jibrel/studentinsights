import React from 'react';

// Render a link that will download a CSV string as a file hen clicked.
export default class DownloadCsvLink extends React.Component {
  // IE hack; see http://msdn.microsoft.com/en-us/library/ie/hh779016.aspx
  onClickDownload(csvText, filename, e) {
    if (!window.navigator.msSaveOrOpenBlob) return;

    e.preventDefault();
    const blob = new Blob([csvText], {type: 'text/csv;charset=utf-8;'});
    window.navigator.msSaveBlob(blob, filename);
  }

  render() {
    const {filename, csvText, style, children} = this.props;
    return (
      <a
        className="DownloadCsvLink"
        href={`data:attachment/csv,${encodeURIComponent(csvText)}`}
        onClick={this.onClickDownload.bind(this, csvText, filename)}
        target="_blank"
        download={filename}
        style={style}>{children}</a>
    );
  }
}
DownloadCsvLink.propTypes = {
  filename: React.PropTypes.string.isRequired,
  csvText: React.PropTypes.string.isRequired,
  children: React.PropTypes.node.isRequired,
  style: React.PropTypes.object
};