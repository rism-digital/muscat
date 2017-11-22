/*
* WidgetWrapper.js
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
 * @class WidgetWrapper
 * Interface-like implementation for widgets interaction to each other; aimed to be modified for dynamic data sources
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {Object} widget either a map, time or table widget
 */
WidgetWrapper = function() {

	var wrapper = this;

	this.setWidget = function(widget) {
		this.widget = widget;
	}

	this.display = function(data) {
		if ( data instanceof Array) {
			GeoTemConfig.datasets = data;
			if ( typeof wrapper.widget != 'undefined') {
				this.widget.initWidget(data);
			}
		}
	};

	Publisher.Subscribe('highlight', this, function(data) {
		if (data == undefined) {
			return;
		}
		if ( typeof wrapper.widget != 'undefined') {
			wrapper.widget.highlightChanged(data);
		}
	});

	Publisher.Subscribe('selection', this, function(data) {
		if ( typeof wrapper.widget != 'undefined') {
			wrapper.widget.selectionChanged(data);
		}
	});

	Publisher.Subscribe('filterData', this, function(data) {
		wrapper.display(data);
	});

	Publisher.Subscribe('rise', this, function(id) {
		if ( typeof wrapper.widget != 'undefined' && typeof wrapper.widget.riseLayer != 'undefined') {
			wrapper.widget.riseLayer(id);
		}
	});

	Publisher.Subscribe('resizeWidget', this, function() {
		if ( typeof wrapper.widget != 'undefined' && typeof wrapper.widget.gui != 'undefined' && typeof wrapper.widget.gui.resize != 'undefined' ) {
			wrapper.widget.gui.resize();
		}
	});

	this.triggerRefining = function(datasets) {
		Publisher.Publish('filterData', datasets, null);
	};

	this.triggerSelection = function(selectedObjects) {
		Publisher.Publish('selection', selectedObjects, this);
	};

	this.triggerHighlight = function(highlightedObjects) {
		Publisher.Publish('highlight', highlightedObjects, this);
	};

	this.triggerRise = function(id) {
		Publisher.Publish('rise', id);
	};

};
