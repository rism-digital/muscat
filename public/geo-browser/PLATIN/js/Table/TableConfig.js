/*
* TableConfig.js
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
 * @class TableConfig
 * Table Configuration File
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
function TableConfig(options) {

	this.options = {
		tableWidth : false, // false or desired width css definition for the table
		tableHeight : false, // false or desired height css definition for the table
		validResultsPerPage : [10, 20, 50, 100], // valid number of elements per page
		initialResultsPerPage : 10, // initial number of elements per page
		tableSorting : true, // true, if sorting of columns should be possible
		tableContentOffset : 250, // maximum display number of characters in a table cell
		tableSelectPage : true, // selection of complete table pages
		tableSelectAll : false, // selection of complete tables
		tableShowSelected : true, // show selected objects only option
		tableKeepShowSelected : true, // don't revert to show all on "reset" (e.g. selection)
		tableInvertSelection : true, // show invert selection option
		tableSelectByText : true, // select objects by full-text search
		tableCreateNewFromSelected : true, // create new dataset from selected objects
		unselectedCellColor : '#EEE', // color for an unselected row/tab
		verticalAlign : 'top', // vertical alignment of the table cells ('top','center','bottom')
	};
	if ( typeof options != 'undefined') {
		$.extend(this.options, options);
	}

};
