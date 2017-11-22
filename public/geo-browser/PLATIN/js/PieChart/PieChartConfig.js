/*
* PieChartConfig.js
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
 * @class PieChartConfig
 * PieChart Configuration File
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 */
function PieChartConfig(options) {

	this.options = {
			restrictPieChartSize : 0.25, // restrict size to percantage of window size (false for no restriction)
			localStoragePrefix : "GeoBrowser_PieChart_", // prefix for value name in LocalStorage
			allowLocalStorage : true, //whether LocalStorage save and load should be allowed (and buttons shown) 
	};
	if ( typeof options != 'undefined') {
		$.extend(this.options, options);
	}

};
