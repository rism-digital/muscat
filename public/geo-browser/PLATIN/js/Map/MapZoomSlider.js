/*
* MapZoomSlider.js
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
 * @class MapZoomSlider
 * GeoTemCo style for map zoom control
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
function MapZoomSlider(parent, orientation) {

	this.parent = parent;

	var zs = this;
	this.div = document.createElement("div");
	this.div.setAttribute('class', 'sliderStyle-' + orientation);

	var sliderContainer = document.createElement("div");
	sliderContainer.setAttribute('class', 'zoomSliderContainer-' + orientation);
	var sliderDiv = document.createElement("div");
	sliderDiv.tabIndex = 1;
	var sliderInputDiv = document.createElement("div");
	sliderDiv.appendChild(sliderInputDiv);
	sliderContainer.appendChild(sliderDiv);
	this.slider = new Slider(sliderDiv, sliderInputDiv, orientation);
	this.div.appendChild(sliderContainer);

	var zoomIn = document.createElement("img");
	zoomIn.src = GeoTemConfig.path + "zoom_in.png";
	zoomIn.setAttribute('class', 'zoomSliderIn-' + orientation);
	zoomIn.onclick = function() {
		zs.parent.zoom(1);
	}
	this.div.appendChild(zoomIn);

	var zoomOut = document.createElement("img");
	zoomOut.src = GeoTemConfig.path + "zoom_out.png";
	zoomOut.setAttribute('class', 'zoomSliderOut-' + orientation);
	zoomOut.onclick = function() {
		zs.parent.zoom(-1);
	}
	this.div.appendChild(zoomOut);

	this.slider.onclick = function() {
		console.info(zs.slider.getValue());
	}

	this.slider.handle.onmousedown = function() {
		var oldValue = zs.slider.getValue();
		document.onmouseup = function() {
			if (!zs.parent.zoom((zs.slider.getValue() - oldValue) / zs.max * zs.levels)) {
				zs.setValue(oldValue);
			}
			document.onmouseup = null;
		}
	}

	this.setValue = function(value) {
		this.slider.setValue(value / this.levels * this.max);
	}

	this.setMaxAndLevels = function(max, levels) {
		this.max = max;
		this.levels = levels;
		this.slider.setMaximum(max);
	}
	//	this.setMaxAndLevels(1000,parent.openlayersMap.getNumZoomLevels());
	//	this.setValue(parent.getZoom());

	this.setLanguage = function() {
		zoomIn.title = GeoTemConfig.getString('zoomIn');
		zoomOut.title = GeoTemConfig.getString('zoomOut');
		this.slider.handle.title = GeoTemConfig.getString('zoomSlider');
	}
}
