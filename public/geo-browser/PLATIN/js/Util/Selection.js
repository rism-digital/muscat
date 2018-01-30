/*
* Selection.js
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
 * @class Selection
 * Selection Class
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {Array} objects array of selected objects
 * @param {Object} widget which belongs to selection
 */
function Selection(objects, widget) {

	this.objects = objects;
	if ( typeof objects == 'undefined') {
		this.objects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++) {
			this.objects.push([]);
		}
	}
	this.widget = widget;

	this.getObjects = function(widget) {
		if (!this.equal(widget)) {
			return this.objects;
		}
		this.objects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++) {
			this.objects.push([]);
		}
		return this.objects;
	};

	this.equal = function(widget) {
		if (this.valid() && this.widget != widget) {
			return false;
		}
		return true;
	};

	this.valid = function() {
		if ( typeof this.widget != 'undefined') {
			return true;
		}
		return false;
	};
	
	this.loadAllObjects = function() {
		allObjects = [];
		$(GeoTemConfig.datasets).each(function(){
			var singleDatasetObjects = []; 
			$(this.objects).each(function(){
				singleDatasetObjects.push(this);
			});
			allObjects.push(singleDatasetObjects);
		});
		this.objects = allObjects;
	};
};

