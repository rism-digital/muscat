/*
* TableGui.js
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
 * @class TableGui
 * Table GUI Implementation
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {TableWidget} parent table widget object
 * @param {HTML object} div parent div to append the table gui
 * @param {JSON} options table configuration
 */
function TableGui(table, div, options) {

	this.tableContainer = div;
	if (options.tableWidth) {
		this.tableContainer.style.width = options.tableWidth;
	}
	if (options.tableHeight) {
		this.tableContainer.style.height = options.tableHeight;
	}
	this.tableContainer.style.position = 'relative';

	this.tabs = document.createElement('div');
	this.tabs.setAttribute('class', 'tableTabs');
	div.appendChild(this.tabs);

	this.input = document.createElement('div');
	this.input.setAttribute('class', 'tableInput');
	div.appendChild(this.input);

};
