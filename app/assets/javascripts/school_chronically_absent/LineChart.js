// import React from 'react';
// import PropTypes from 'prop-types';
// import HighchartsWrapper from '../components/HighchartsWrapper';

// // Component for all charts in the dashboard page.
// export default class LineChart extends React.Component{

//   render() {
//     return (
//       <div id={this.props.id} className="LineChart" style={styles.root}>
//         <HighchartsWrapper
//           style={{flex: 1}}
//           chart={{
//             type: 'line',
//             events: {
//               click: this.props.onBackgroundClick
//             }
//           }}
//           credits={false}
//           xAxis={this.props.xAxis}
//           plotOptions={{
//             series: {
//               animation: this.props.animation,
//               cursor: (this.props.onColumnClick) ? 'pointer' : 'default',
//               events: {
//                 click: this.props.onColumnClick
//               }
//             }
//           }}
//           title={{text: this.props.titleText}}
//           yAxis={{
//             min: this.props.yAxisMin,
//             max: this.props.yAxisMax,
//             allowDecimals: true,
//             title: {text: this.props.measureText}
//           }}
//           tooltip={this.props.tooltip}
//           series={[
//             {
//               showInLegend: false,
//               data: this.props.seriesData,
//               ...(this.props.series || {})
//             }
//           ]} />
//       </div>
//     );
//   }
// }

// LineChart.propTypes = {
//   id: PropTypes.string.isRequired, // short string identifier for links to jump to
//   xAxis: PropTypes.object,
//   seriesData: PropTypes.array.isRequired, // array of JSON event objects.
//   yAxisMin: PropTypes.number,
//   yAxisMax: PropTypes.number,
//   titleText: PropTypes.string, //discipline dashboard makes its own title
//   measureText: PropTypes.string.isRequired,
//   tooltip: PropTypes.object.isRequired,
//   animation: PropTypes.bool,
//   onColumnClick: PropTypes.func,
//   onBackgroundClick: PropTypes.func,
//   series: PropTypes.object
// };
// LineChart.defaultProps = {
//   animation: true
// };

// const styles = {
//   root: {
//     flex: 1,
//     width: '100%',
//     padding: 10,
//     display: 'flex'
//   }
// };