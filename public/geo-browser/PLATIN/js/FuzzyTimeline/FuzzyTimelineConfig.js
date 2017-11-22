/*
* FuzzyTimelineConfig.js
*
* Copyright (c) 2013, Sebastian Kruse. All rights reserved.
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
 * @class FuzzyTimelineConfig
 * FuzzyTimeline Configuration File
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 */
function FuzzyTimelineConfig(options) {

	this.options = {
			//TODO: experiment with number of ticks, 150 seems to be ok for now
			maxBars : 50,
			maxDensityTicks : 150,
			/*drawing modes: 
			 *	fuzzy - weight is distributed over all spans an object overlaps, so that the sum remains the weight, 
			 *	stacking - every span that on object overlaps gets the complete weight (limited by the amount the span is overlapped, e.g. first span and last might get less) 
			 */
			timelineMode : 'stacking',
			showRangePiechart : false,
			backgroundColor : "#EEEEEE",
			showYAxis : true,
			//whether time-spans that "enlargen" the plot are allowed
			//if set to true, a span that creates more "bars" than fit on the screen
			//will lead to a width-increase of the chart (and a scroll bar appears)
			showAllPossibleSpans : true,
	};
	if ( typeof options != 'undefined') {
		$.extend(this.options, options);
	}

};
