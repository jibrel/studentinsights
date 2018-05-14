import React from 'react';

// Visual component showing a horizontal bar broken down into a few colors
// showing percent of students of different attributes (eg, DIBELS scores, gender identity).
export default class BreakdownBar extends React.Component {
  totalCount() {
    const {items} = this.props;
    return items.reduce((sum, item) => sum + item.width, 0);
  }

  scale(count) {
    const totalCount = this.totalCount();
    return `${Math.ceil(100 * count / totalCount)}%`;
  }

  render() {
    const {items,height, style = {}} = this.props;    
    return (
      <div className="BreakdownBar" style={{height, ...style}}>
        <div style={{position: 'relative', width: '100%', height}}>
          {items.map(item => this.renderBarAndLabel(item))}
        </div>
      </div>
    );
  }


  renderBarAndLabel({key, left, width, color}) {
    const {height, labelTop, innerStyle} = this.props;

    if (width === 0) return;
    return (
      <div key={key}>
        <div style={{
          position: 'absolute',
          background: color,
          left: this.scale(left),
          width: this.scale(width),
          height,
          ...innerStyle
        }}>{'\u00A0'}</div>
        {width > 0 && 
          <div style={{
            color,
            position: 'absolute',
            textAlign: 'right',
            left: this.scale(left),
            width: this.scale(width),
            top: labelTop,
            paddingRight: 1,
            ...innerStyle
          }}>{width}</div>}
      </div>
    );
  }
}

BreakdownBar.propTypes = {
  items: React.PropTypes.arrayOf(React.PropTypes.shape({
    left: React.PropTypes.number.isRequired,
    width: React.PropTypes.number.isRequired,
    color: React.PropTypes.string.isRequired
  })).isRequired,
  height: React.PropTypes.number.isRequired,
  labelTop: React.PropTypes.number.isRequired,
  style: React.PropTypes.object,
  innerStyle: React.PropTypes.object
};
