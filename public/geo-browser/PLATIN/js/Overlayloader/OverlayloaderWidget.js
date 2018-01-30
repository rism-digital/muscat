/*
* OverlayloaderWidget.js
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
 * @class OverlayloaderWidget
 * OverlayloaderWidget Implementation
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {WidgetWrapper} core wrapper for interaction to other widgets
 * @param {HTML object} div parent div to append the Overlayloader widget div
 * @param {JSON} options user specified configuration that overwrites options in OverlayloaderConfig.js
 */
OverlayloaderWidget = function(core, div, options) {

	this.core = core;
	this.core.setWidget(this);

	this.options = (new OverlayloaderConfig(options)).options;
	this.gui = new OverlayloaderGui(this, div, this.options);
	
	this.attachedMapWidgets = new Array();
	
	this.overlayLoader = new Overlayloader(this);
}

OverlayloaderWidget.prototype = {

	initWidget : function() {

		var overlayloaderWidget = this;
	},

	highlightChanged : function(objects) {
		if( !GeoTemConfig.highlightEvents ){
			return;
		}
	},

	selectionChanged : function(selection) {
		if( !GeoTemConfig.selectionEvents ){
			return;
		}
	},

	triggerHighlight : function(item) {
	},

	tableSelection : function() {
	},

	deselection : function() {
	},

	filtering : function() {
	},

	inverseFiltering : function() {
	},

	triggerRefining : function() {
	},

	reset : function() {
	},
	
	attachMapWidget : function(widget) {
		this.attachedMapWidgets.push(widget);
	}
};
