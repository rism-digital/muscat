/*
* MapControl.js
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
 * @class MapControl
 * Generic map control interface
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
function MapControl(map, button, label, onActivate, onDeactivate) {

	var control = this;
	this.button = button;
	this.enabled = true;
	this.activated = false;
	this.label = label;

	if (this.button != null) {
		$(this.button).addClass(label + 'Deactivated');
		$(this.button).attr("title", GeoTemConfig.getString(GeoTemConfig.language, label));
		//vhz
		$(this.button).click(function() {
			control.checkStatus();
		});
	}

	this.checkStatus = function() {
		if (control.enabled) {
			if ( typeof map.activeControl != 'undefined') {
				if (control.activated) {
					control.deactivate();
				} else {
					map.activeControl.deactivate();
					control.activate();
				}
			} else {
				control.activate();
			}
		}
	};

	this.setButtonClass = function(removeClass, addClass) {
		if (this.button != null) {
			$(this.button).removeClass(label + removeClass);
			$(this.button).addClass(label + addClass);
			$(this.button).attr("title", GeoTemConfig.getString(GeoTemConfig.language, label));
		}
	};

	this.disable = function() {
		this.enabled = false;
		this.setButtonClass('Deactivated', 'Disabled');
	};

	this.enable = function() {
		this.enabled = true;
		this.setButtonClass('Disabled', 'Deactivated');
	};

	this.activate = function() {
		onActivate();
		this.activated = true;
		this.setButtonClass('Deactivated', 'Activated');
		map.activeControl = this;
	};

	this.deactivate = function() {
		onDeactivate();
		this.activated = false;
		this.setButtonClass('Activated', 'Deactivated');
		map.activeControl = undefined;
	};

};
