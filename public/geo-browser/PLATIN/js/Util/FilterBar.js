/*
* FilterBar.js
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
 * @class FilterBar
 * Implementation for FilterBar Object
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {Object} parent parent to call filter functions
 * @param {HTML object} parentDiv div to append filter buttons
 */
FilterBarFactory = {
	filterBarArray :[],
	push : function(newFilterBar){
		FilterBarFactory.filterBarArray.push(newFilterBar);
	},
	resetAll : function(show) {
		$(FilterBarFactory.filterBarArray).each(function(){
			if (show) {
				this.filter.setAttribute('class', 'smallButton filter');
				this.filterInverse.setAttribute('class', 'smallButton filterInverse');
				this.cancelSelection.setAttribute('class', 'smallButton filterCancel');
			} else {
				this.filter.setAttribute('class', 'smallButton filterDisabled');
				this.filterInverse.setAttribute('class', 'smallButton filterInverseDisabled');
				this.cancelSelection.setAttribute('class', 'smallButton filterCancelDisabled');
			}
		});
	}
};

function FilterBar(parent, parentDiv) {
	FilterBarFactory.push(this);

	var bar = this;

	this.filter = document.createElement('div');
	this.filter.setAttribute('class', 'smallButton filterDisabled');
	this.filter.onclick = function() {
		parent.filtering();
	};

	this.filterInverse = document.createElement('div');
	this.filterInverse.setAttribute('class', 'smallButton filterInverseDisabled');
	this.filterInverse.onclick = function() {
		parent.inverseFiltering();
	};
	if (!GeoTemConfig.inverseFilter) {
		this.filterInverse.style.display = 'none';
	}

	this.cancelSelection = document.createElement('div');
	this.cancelSelection.setAttribute('class', 'smallButton filterCancelDisabled');
	this.cancelSelection.onclick = function() {
		parent.deselection();
	};

	this.appendTo = function(parentDiv) {
		parentDiv.appendChild(this.filter);
		parentDiv.appendChild(this.filterInverse);
		parentDiv.appendChild(this.cancelSelection);
	}
	if ( typeof parentDiv != 'undefined') {
		this.appendTo(parentDiv);
	}

	this.reset = function(show) {
		FilterBarFactory.resetAll(show);
	};

};
