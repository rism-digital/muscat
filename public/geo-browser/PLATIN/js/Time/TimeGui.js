/*
* TimeGui.js
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
 * @class TimeGui
 * Time GUI Implementation
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {TimeWidget} parent time widget object
 * @param {HTML object} div parent div to append the time gui
 * @param {JSON} options time configuration
 */
function TimeGui(plot, div, options, iid) {

	var gui = this;

	this.plot = plot;

	this.container = div;
	if (options.timeWidth) {
		this.container.style.width = options.timeWidth;
	}
	if (options.timeHeight) {
		this.container.style.height = options.timeHeight;
	}
	this.container.style.position = 'relative';

	var w = this.container.offsetWidth;
	var h = this.container.offsetHeight;

	var toolbarTable = document.createElement("table");
	toolbarTable.setAttribute('class', 'ddbToolbar');
	this.container.appendChild(toolbarTable);

	this.plotWindow = document.createElement("div");
	this.plotWindow.id = "plotWindow"+iid;
	this.plotWindow.setAttribute('class', 'plotWindow');
//	this.plotWindow.style.width = w + "px";

	this.plotWindow.style.height = (h + 12) + "px";
	this.container.style.height = (h + 12) + "px";

	this.plotWindow.onmousedown = function() {
		return false;
	}

	this.plotContainer = document.createElement("div");
	this.plotContainer.id = "plotContainer"+iid;
	this.plotContainer.setAttribute('class', 'plotContainer');
//	this.plotContainer.style.width = w + "px";
	this.plotContainer.style.height = h + "px";
	this.plotContainer.style.position = "absolute";
	this.plotContainer.style.zIndex = 0;
	this.plotContainer.style.top = "12px";
	this.plotWindow.appendChild(this.plotContainer);
	this.container.appendChild(this.plotWindow);

	this.timeplotDiv = document.createElement("div");
	this.timeplotDiv.style.left = "16px";
	this.timeplotDiv.style.width = (w - 32) + "px";
	this.timeplotDiv.style.height = h + "px";
	this.plotContainer.appendChild(this.timeplotDiv);

	var cv = document.createElement("canvas");
	cv.setAttribute('class', 'plotCanvas');
	this.plotWindow.appendChild(cv);
	if (!cv.getContext && G_vmlCanvasManager)
		cv = G_vmlCanvasManager.initElement(cv);
	var ctx = cv.getContext('2d');

	var setCanvas = function(){
		cv.width = gui.plotWindow.clientWidth;
		cv.height = gui.plotWindow.clientHeight;
		var gradient = ctx.createLinearGradient(0, 0, 0, gui.plotWindow.clientHeight);
		gradient.addColorStop(0, options.timeCanvasFrom);
		gradient.addColorStop(1, options.timeCanvasTo);
		ctx.fillStyle = gradient;
		ctx.fillRect(0, 0, gui.plotWindow.clientWidth, gui.plotWindow.clientHeight);
	}
	setCanvas();

	this.resize = function(){
		gui.timeplotDiv.style.width = (gui.container.offsetWidth - 32) + "px";
		ctx.clearRect(0,0,gui.plotWindow.clientWidth, gui.plotWindow.clientHeight);
		if( typeof plot.datasets != "undefined" ){
			plot.redrawPlot();
			plot.resetOpacityPlots();
		}
		setCanvas();
	};

	var titles = document.createElement("tr");
	toolbarTable.appendChild(titles);
	var tools = document.createElement("tr");
	toolbarTable.appendChild(tools);

	this.timeUnitTitle = document.createElement("td");
	this.timeUnitTitle.innerHTML = GeoTemConfig.getString('timeUnit');
	this.timeUnitSelector = document.createElement("td");
	if (options.unitSelection) {
		tools.appendChild(this.timeUnitSelector);
		titles.appendChild(this.timeUnitTitle);
	}

	this.timeAnimation = document.createElement("td");
	this.timeAnimation.innerHTML = GeoTemConfig.getString('timeAnimation');
	var timeAnimationTools = document.createElement("td");

	var status;
	this.updateAnimationButtons = function(s) {
		status = s;
		if (status == 0) {
			gui.playButton.setAttribute('class', 'smallButton playDisabled');
			gui.pauseButton.setAttribute('class', 'smallButton pauseDisabled');
		} else if (status == 1) {
			gui.playButton.setAttribute('class', 'smallButton playEnabled');
			gui.pauseButton.setAttribute('class', 'smallButton pauseDisabled');
		} else {
			gui.playButton.setAttribute('class', 'smallButton playDisabled');
			gui.pauseButton.setAttribute('class', 'smallButton pauseEnabled');
		}
	};
	this.playButton = document.createElement("div");
	this.playButton.title = GeoTemConfig.getString('playButton');
	timeAnimationTools.appendChild(this.playButton);
	this.playButton.onclick = function() {
		if (status == 1) {
			plot.play();
		}
	}

	this.pauseButton = document.createElement("div");
	this.pauseButton.title = GeoTemConfig.getString('pauseButton');
	timeAnimationTools.appendChild(this.pauseButton);
	this.pauseButton.onclick = function() {
		if (status == 2) {
			plot.stop();
		}
	}

	this.valueScale = document.createElement("td");
	this.valueScale.innerHTML = GeoTemConfig.getString('valueScale');
	var valueScaleTools = document.createElement("td");

	var linearPlot;
	var setValueScale = function(linScale) {
		if (linearPlot != linScale) {
			linearPlot = linScale;
			if (linearPlot) {
				gui.linButton.setAttribute('class', 'smallButton linearPlotActivated');
				gui.logButton.setAttribute('class', 'smallButton logarithmicPlotDeactivated');
				plot.drawLinearPlot();
			} else {
				gui.linButton.setAttribute('class', 'smallButton linearPlotDeactivated');
				gui.logButton.setAttribute('class', 'smallButton logarithmicPlotActivated');
				plot.drawLogarithmicPlot();
			}
		}
	};
	this.linButton = document.createElement("div");
	this.linButton.title = GeoTemConfig.getString('linearPlot');
	valueScaleTools.appendChild(this.linButton);
	this.linButton.onclick = function() {
		setValueScale(true);
	}

	this.logButton = document.createElement("div");
	this.logButton.title = GeoTemConfig.getString('logarithmicPlot');
	valueScaleTools.appendChild(this.logButton);
	this.logButton.onclick = function() {
		setValueScale(false);
	}
	if (options.rangeAnimation) {
		titles.appendChild(this.timeAnimation);
		tools.appendChild(timeAnimationTools);
		this.updateAnimationButtons(0);
	}

	if (options.scaleSelection) {
		titles.appendChild(this.valueScale);
		tools.appendChild(valueScaleTools);
		setValueScale(options.linearScale);
	}

	if (GeoTemConfig.allowFilter) {
		this.filterTitle = document.createElement("td");
		titles.appendChild(this.filterTitle);
		this.filterTitle.innerHTML = GeoTemConfig.getString('filter');
		this.filterOptions = document.createElement("td");
		tools.appendChild(this.filterOptions);
	}

	if (options.dataInformation) {
		this.infoTitle = document.createElement("td");
		this.infoTitle.innerHTML = options.timeTitle;
		titles.appendChild(this.infoTitle);
		var timeSum = document.createElement("td");
		this.timeElements = document.createElement("div");
		this.timeElements.setAttribute('class', 'ddbElementsCount');
		timeSum.appendChild(this.timeElements);
		tools.appendChild(timeSum);
	}

	/*
	 var tooltip = document.createElement("div");
	 tooltip.setAttribute('class','ddbTooltip');
	 toolbarTable.appendChild(tooltip);

	 tooltip.onmouseover = function(){
	 /*
	 getPublisher().Publish('TooltipContent', {
	 content: GeoTemConfig.getString(GeoTemConfig.language,'timeHelp'),
	 target: $(tooltip)
	 });

	 }
	 tooltip.onmouseout = function(){
	 //getPublisher().Publish('TooltipContent');
	 }
	 */

	this.setHeight = function() {
		this.container.style.height = (this.plotWindow.offsetHeight + toolbarTable.offsetHeight) + "px";
	};

	this.updateTimeQuantity = function(count) {
		if (options.dataInformation) {
			this.plotCount = count;
			if (count != 1) {
				this.timeElements.innerHTML = this.beautifyCount(count) + " " + GeoTemConfig.getString('results');
			} else {
				this.timeElements.innerHTML = this.beautifyCount(count) + " " + GeoTemConfig.getString('result');
			}
		}
	}

	this.setTimeUnitDropdown = function(units) {
		$(this.timeUnitSelector).empty();
		var gui = this;
		var timeUnits = [];
		var addUnit = function(unit, index) {
			var setUnit = function() {
				gui.plot.setTimeUnit(unit.unit);
			}
			timeUnits.push({
				name : unit.label,
				onclick : setUnit
			});
		}
		for (var i = 0; i < units.length; i++) {
			addUnit(units[i], i);
		}
		this.timeUnitDropdown = new Dropdown(this.timeUnitSelector, timeUnits, GeoTemConfig.getString('selectTimeUnit'), '100px');
		this.timeUnitDropdown.setEntry(0);
	}
	this.setTimeUnitDropdown([{
		name : 'none',
		id : -1
	}]);

	this.beautifyCount = function(count) {
		var c = count + '';
		var p = 0;
		var l = c.length;
		while (l - p > 3) {
			p += 3;
			c = c.substring(0, l - p) + "." + c.substring(l - p);
			p++;
			l++;
		}
		return c;
	}

	this.hideTimeUnitSelection = function() {
		this.timeUnitTitle.style.display = 'none';
		this.timeUnitSelector.style.display = 'none';
	}
};
