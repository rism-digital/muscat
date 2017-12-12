/*
* TimeConfig.js
*
* Copyright (c) 2012, Stefan Jänicke. All rights reserved.
*
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This library is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public
* License along with this library; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
* MA 02110-1301  USA
*/

/**
 * @class TimeConfig
 * Time Configuration File
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
function TimeConfig(options) {

	this.options = {
		timeTitle : 'GeoTemCo Time View', // title will be shown in timeplot header
		timeIndex : 0, // index = position in date array; for multiple dates the 2nd timeplot refers to index 1
		timeWidth : false, // false or desired width css definition for the timeplot
		timeHeight : '100px', // false or desired height css definition for the timeplot
		defaultMinDate : new Date(2012, 0, 1), // required, when empty timelines are possible
		defaultMaxDate : new Date(), // required, when empty timelines are possible
		timeCanvasFrom : '#EEE', // time widget background gradient color top
		timeCanvasTo : '#EEE', // time widget background gradient color bottom
		rangeBoxColor : "white", // fill color for time range box
		rangeBorder : "1px solid #de7708", // border of frames
		dataInformation : true, // show/hide data information
		rangeAnimation : true, // show/hide animation buttons
		scaleSelection : true, // show/hide scale selection buttons
		linearScale : true, // true for linear value scaling, false for logarithmic
		unitSelection : true, // show/hide time unit selection dropdown
		timeUnit : -1, // minimum temporal unit (SimileAjax.DateTime or -1 if none) of the data
		timeMerge : false // if the elements of distinct datasets should be merged into one set or not
	};
	if ( typeof options != 'undefined') {
		$.extend(this.options, options);
	}

};
