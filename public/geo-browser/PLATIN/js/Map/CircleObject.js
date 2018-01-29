/*
* CircleObject.js
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
 * @class CircleObject
 * circle object aggregate for the map
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {float} x the x (longitude) value for the circle
 * @param {float} y the y (latitude) value for the circle
 * @param {DataObject[]} elements array of data objects belonging to the circle
 * @param {float} radius the resulting radius (in pixel) for the circle
 * @param {int} search dataset index
 * @param {int} weight summed weight of all elements
 * @param {JSON} fatherBin bin of the circle object if its part of a circle pack
 */
CircleObject = function(originX, originY, shiftX, shiftY, elements, radius, search, weight, fatherBin) {

	this.originX = originX;
	this.originY = originY;
	this.shiftX = shiftX;
	this.shiftY = shiftY;
	this.elements = elements;
	this.radius = radius;
	this.search = search;
	this.weight = weight;
	this.overlay = 0;
	this.overlayElements = [];
	this.smoothness = 0;
	this.fatherBin = fatherBin;

	this.feature
	this.olFeature
	this.percentage = 0;
	this.selected = false;

};

CircleObject.prototype = {

	/**
	 * sets the OpenLayers point feature for this point object
	 * @param {OpenLayers.Feature} pointFeature the point feature for this object
	 */
	setFeature : function(feature) {
		this.feature = feature;
	},

	/**
	 * sets the OpenLayers point feature for this point object to manage its selection status
	 * @param {OpenLayers.Feature} olPointFeature the overlay point feature for this object
	 */
	setOlFeature : function(olFeature) {
		this.olFeature = olFeature;
	},

	reset : function() {
		this.overlay = 0;
		this.overlayElements = [];
		this.smoothness = 0;
	},

	setSelection : function(s) {
		this.selected = s;
	},

	toggleSelection : function() {
		this.selected = !this.selected;
	}
};
