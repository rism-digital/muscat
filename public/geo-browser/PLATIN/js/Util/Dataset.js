/*
* Dataset.js
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
 * @class Dataset
 * GeoTemCo's Dataset class
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {Array} objects data item arrays from different datasets
 * @param {String} label label for the datasets
 */
Dataset = function(objects, label, url, type) {

	this.objects = objects;
	this.label = label;
	this.url = url;
	this.type = type;
	
	this.color;
	
	//if the user can change shapes, every dataset needs a default shape
	if (GeoTemConfig.allowUserShapeAndColorChange){
		this.graphic={
				shape: "circle",
				rotation: 0
		}
	}
	
	Publisher.Publish('datasetAfterCreation', this);
}
