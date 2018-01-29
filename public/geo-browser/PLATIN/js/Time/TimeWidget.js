/*
* TimeWidget.js
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
 * @class TimeWidget
 * TableWidget Implementation
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {TimeWrapper} core wrapper for interaction to other widgets
 * @param {HTML object} div parent div to append the time widget div
 * @param {JSON} options user specified configuration that overwrites options in TimeConfig.js
 */
TimeWidget = function(core, div, options) {

	this.core = core;
	this.core.setWidget(this);
	this.timeplot
	this.dataSources
	this.eventSources
	this.tds
	this.timeGeometry
	this.valueGeometry
	this.canvas

	this.leftFlagPole
	this.rightFlagPole
	this.rangeBox
	this.leftHandle
	this.rightHandle

	this.leftFlagPos = null;
	this.leftFlagTime = null;
	this.rightFlagPos = null;
	this.rightFlagTime = null;

	this.mouseDownTime
	this.mouseUpTime
	this.mouseTempTime
	this.mouseDownPos
	this.mouseUpPos
	this.mouseTempPos

	this.status
	this.slider

	this.iid = GeoTemConfig.getIndependentId('time');
	this.options = (new TimeConfig(options)).options;
	this.gui = new TimeGui(this, div, this.options, this.iid);
	this.initialize();

}

TimeWidget.prototype = {

	/**
	 * clears the timeplot canvas and the timeGeometry properties
	 */
	clearTimeplot : function() {
		this.timeplot._clearCanvas();
		this.timeGeometry._earliestDate = null;
		this.timeGeometry._latestDate = null;
		this.valueGeometry._minValue = 0;
		this.valueGeometry._maxValue = 0;
		this.highlightedSlice = undefined;
		this.timeGeometry._clearLabels();
		this.selection = new Selection();
	},

	/**
	 * initializes the timeplot elements with arrays of time objects
	 * @param {TimeObject[][]} timeObjects an array of time objects from different (1-4) sets
	 */
	initWidget : function(datasets) {
		this.datasets = datasets;
		var timeObjects = [];
		for (var i = 0; i < datasets.length; i++) {
			timeObjects.push(datasets[i].objects);
		}
		this.clearTimeplot();
		this.reset();
		for (var i = 0; i < this.timeplot._plots.length; i++) {
			this.timeplot._plots[i].dispose();
		}
		this.dataSources = new Array();
		this.plotInfos = new Array();
		this.eventSources = new Array();
		var granularity = 0;
		this.count = 0;
		for (var i = 0; i < timeObjects.length; i++) {
			if( i==0 || !this.options.timeMerge ){
				var eventSource = new Timeplot.DefaultEventSource();
				var dataSource = new Timeplot.ColumnSource(eventSource, 1);
				this.dataSources.push(dataSource);
				this.eventSources.push(eventSource);
				var c = GeoTemConfig.getColor(i);
				var plotInfo = Timeplot.createPlotInfo({
					id : "plot" + i,
					dataSource : dataSource,
					timeGeometry : this.timeGeometry,
					valueGeometry : this.valueGeometry,
					fillGradient : false,
					lineColor : 'rgba(' + c.r1 + ',' + c.g1 + ',' + c.b1 + ', 1)',
					fillColor : 'rgba(' + c.r0 + ',' + c.g0 + ',' + c.b0 + ', 0.3)',
					showValues : true
				});
				this.plotInfos.push(plotInfo);
			}
			for (var j = 0; j < timeObjects[i].length; j++) {
				var o = timeObjects[i][j];
				if (o.isTemporal) {
					var g = o.dates[this.options.timeIndex].granularity;
					if (g == null) {
						continue;
					} else if (g > granularity) {
						granularity = g;
					}
					this.count += o.weight;
				}
			}
		}
		this.timeGeometry._granularity = granularity;
		this.timeGeometry._clearLabels();
		this.timeplot.resetPlots(this.plotInfos);
		if (this.plotInfos.length == 0) {
			this.initLabels(this.timeplot.regularGrid());
			return;
		}
		this.timeGeometry.extendedDataSource = this.tds;
		this.tds.initialize(this.dataSources, this.eventSources, timeObjects, granularity, this.options.timeUnit, this.gui.timeplotDiv.offsetWidth);
		this.gui.setTimeUnitDropdown(this.tds.availableUnits);
		this.gui.timeUnitDropdown.setEntry(this.tds.getUnitIndex());
		var plots = this.timeplot._plots;
		for (var i = 0; i < plots.length; i++) {
			plots[i].pins = [];
			plots[i].style = this.style;
			for (var j = 0; j < this.tds.getSliceNumber(); j++) {
				plots[i].pins.push({
					height : 0,
					count : 0
				});
			}
		}
		/*
		 var levels = Math.round( (this.tds.timeSlices.length-3)/2 );
		 if( GeoTemConfig.timeZoom ){
		 this.zoomSlider.setMaxAndLevels(levels,levels);
		 }
		 */
		this.timeplot.repaint();
		this.timeplot._resizeCanvas();
		// set maximum number of slider steps
		var slices = this.tds.timeSlices.length;
		var numSlices = Math.floor(slices / this.canvas.width * this.canvas.height + 0.5);

		this.initLabels([]);
		this.initOverview();
		this.gui.updateTimeQuantity(this.count);

	},

	setTimeUnit : function(unit) {
		this.clearTimeplot();
		this.reset();
		this.tds.setTimeUnit(unit);
		var plots = this.timeplot._plots;
		for (var i = 0; i < plots.length; i++) {
			plots[i].pins = [];
			plots[i].style = this.style;
			for (var j = 0; j < this.tds.getSliceNumber(); j++) {
				plots[i].pins.push({
					height : 0,
					count : 0
				});
			}
		}
		this.initLabels([]);
	},

	/**
	 * initializes the timeplot for the Spatio Temporal Interface.
	 * all elements (including their events) that are needed for user interaction are instantiated here, the slider element as well
	 */
	initialize : function() {

		this.status = 0;
		this.selection = new Selection();
		this.paused = true;
		this.dataSources = new Array();
		this.plotInfos = new Array();
		this.eventSources = new Array();
		this.timeGeometry = new Timeplot.DefaultTimeGeometry({
			gridColor : "#000000",
			axisLabelsPlacement : "top"
		});
		this.style = 'graph';
		this.timeGeometry._hideLabels = true;
		this.timeGeometry._granularity = 0;
		this.valueGeometry = new Timeplot.LogarithmicValueGeometry({
			min : 0
		});
		this.valueGeometry.actLinear();

		var plot = this;

		this.timeplot = Timeplot.create(this.gui.timeplotDiv, this.plotInfos);
		this.tds = new TimeDataSource(this.options);

		this.canvas = this.timeplot.getCanvas();

		this.leftFlagPole = this.timeplot.putDiv("leftflagpole", "timeplot-dayflag-pole");
		this.rightFlagPole = this.timeplot.putDiv("rightflagpole", "timeplot-dayflag-pole");
		SimileAjax.Graphics.setOpacity(this.leftFlagPole, 50);
		SimileAjax.Graphics.setOpacity(this.rightFlagPole, 50);

		this.rangeBox = this.timeplot.putDiv("rangebox", "range-box");
		this.rangeBox.style.backgroundColor = plot.options.rangeBoxColor;
		this.rangeBox.style.border = plot.options.rangeBorder;

		this.leftHandle = document.createElement("div");
		this.rightHandle = document.createElement("div");
		this.gui.plotWindow.appendChild(this.leftHandle);
		this.gui.plotWindow.appendChild(this.rightHandle);
		this.leftHandle.title = GeoTemConfig.getString('leftHandle');
		this.rightHandle.title = GeoTemConfig.getString('rightHandle');

		this.leftHandle.style.backgroundImage = "url(" + GeoTemConfig.path + "leftHandle.png" + ")";
		this.leftHandle.setAttribute('class', 'plotHandle plotHandleIcon');
		this.rightHandle.style.backgroundImage = "url(" + GeoTemConfig.path + "rightHandle.png" + ")";
		this.rightHandle.setAttribute('class', 'plotHandle plotHandleIcon');

		this.poles = this.timeplot.putDiv("poles", "pole");
		this.timeplot.placeDiv(this.poles, {
			left : 0,
			bottom : 0,
			width : this.canvas.width,
			height : this.canvas.height,
			display : "block"
		});
		this.poles.appendChild(document.createElement("canvas"));

		this.filterBar = new FilterBar(this, this.gui.filterOptions);

		var plot = this;

		this.dragButton = document.createElement("div");
		this.dragButton.title = GeoTemConfig.getString('dragTimeRange');
		this.cancelButton = document.createElement("div");
		this.cancelButton.title = GeoTemConfig.getString('clearSelection');
		this.cancelButton.onclick = function() {
			plot.deselection();
		}

		this.toolbar = document.createElement("div");
		this.toolbar.setAttribute('class', 'plotToolbar');
		this.toolbar.style.borderTop = plot.options.rangeBorder;
		this.toolbar.style.textAlign = "center";
		this.gui.plotWindow.appendChild(this.toolbar);

		this.toolbarAbsoluteDiv = document.createElement("div");
		this.toolbarAbsoluteDiv.setAttribute('class', 'absoluteToolbar');
		this.toolbar.appendChild(this.toolbarAbsoluteDiv);

		this.dragButton.setAttribute('class', 'dragTimeRangeAlt');
		this.dragButton.style.backgroundImage = "url(" + GeoTemConfig.path + "drag.png" + ")";
		//        	this.zoomButton.setAttribute('class','zoomRangeAlt');
		this.cancelButton.setAttribute('class', 'cancelRangeAlt');
		this.toolbarAbsoluteDiv.appendChild(this.dragButton);
		this.toolbarAbsoluteDiv.style.width = this.dragButton.offsetWidth + "px";
		//	        this.gui.plotWindow.appendChild(this.zoomButton);
		this.gui.plotWindow.appendChild(this.cancelButton);

		this.overview = document.createElement("div");
		this.overview.setAttribute('class', 'timeOverview');
		this.gui.plotWindow.appendChild(this.overview);

		var mousedown = false;
		this.shift = function(shift) {
			if (!mousedown) {
				return;
			}
			if (plot.tds.setShift(shift)) {
				plot.redrawPlot();
			}
			setTimeout(function() {
				plot.shift(shift);
			}, 200);
		}
		var shiftPressed = function(shift) {
			mousedown = true;
			document.onmouseup = function() {
				mousedown = false;
				document.onmouseup = null;
			}
			plot.shift(shift);
		}

		this.shiftLeft = document.createElement("div");
		this.shiftLeft.setAttribute('class', 'shiftLeft');
		this.gui.plotWindow.appendChild(this.shiftLeft);
		this.shiftLeft.onmousedown = function() {
			shiftPressed(1);
		}

		this.shiftRight = document.createElement("div");
		this.shiftRight.setAttribute('class', 'shiftRight');
		this.gui.plotWindow.appendChild(this.shiftRight);
		this.shiftRight.onmousedown = function() {
			shiftPressed(-1);
		}

		this.plotLabels = document.createElement("div");
		this.plotLabels.setAttribute('class', 'plotLabels');
		this.gui.plotWindow.appendChild(this.plotLabels);

		this.initLabels(this.timeplot.regularGrid());

		//Finds the time corresponding to the position x on the timeplot
		var getCorrelatedTime = function(x) {
			if (x >= plot.canvas.width)
				x = plot.canvas.width;
			if (isNaN(x) || x < 0)
				x = 0;
			var t = plot.timeGeometry.fromScreen(x);
			if (t == 0)
				return;
			return plot.dataSources[0].getClosestValidTime(t);
		}
		//Finds the position corresponding to the time t on the timeplot
		var getCorrelatedPosition = function(t) {
			var x = plot.timeGeometry.toScreen(t);
			if (x >= plot.canvas.width)
				x = plot.canvas.width;
			if (isNaN(x) || x < 0)
				x = 0;
			return x;
		}
		//Maps the 2 positions in the right order to left and right bound of the chosen timeRange
		var mapPositions = function(pos1, pos2) {
			if (pos1 > pos2) {
				plot.leftFlagPos = pos2;
				plot.rightFlagPos = pos1;
			} else {
				plot.leftFlagPos = pos1;
				plot.rightFlagPos = pos2;
			}
			plot.leftFlagTime = plot.dataSources[0].getClosestValidTime(plot.timeGeometry.fromScreen(plot.leftFlagPos));
			plot.rightFlagTime = plot.dataSources[0].getClosestValidTime(plot.timeGeometry.fromScreen(plot.rightFlagPos));
		}
		//Sets the divs corresponding to the actual chosen timeRange
		var setRangeDivs = function() {
			plot.leftFlagPole.style.visibility = "visible";
			plot.rightFlagPole.style.visibility = "visible";
			plot.rangeBox.style.visibility = "visible";
			plot.timeplot.placeDiv(plot.leftFlagPole, {
				left : plot.leftFlagPos,
				bottom : 0,
				height : plot.canvas.height,
				display : "block"
			});
			plot.timeplot.placeDiv(plot.rightFlagPole, {
				left : plot.rightFlagPos,
				bottom : 0,
				height : plot.canvas.height,
				display : "block"
			});
			var boxWidth = plot.rightFlagPos - plot.leftFlagPos;
			if (plot.popup) {
				plot.popupClickDiv.style.visibility = "visible";
				plot.timeplot.placeDiv(plot.popupClickDiv, {
					left : plot.leftFlagPos,
					width : boxWidth + 1,
					height : plot.canvas.height,
					display : "block"
				});
			}
			plot.timeplot.placeDiv(plot.rangeBox, {
				left : plot.leftFlagPos,
				width : boxWidth + 1,
				height : plot.canvas.height,
				display : "block"
			});
			var plots = plot.timeplot._plots;
			for ( i = 0; i < plots.length; i++) {
				plots[i].fullOpacityPlot(plot.leftFlagTime, plot.rightFlagTime, plot.leftFlagPos, plot.rightFlagPos, GeoTemConfig.getColor(i));
				plots[i].opacityPlot.style.visibility = "visible";
			}
			var unit = plot.tds.unit;

			var top = plot.gui.plotContainer.offsetTop;
			var left = plot.gui.plotContainer.offsetLeft;
			var leftPos = plot.leftFlagPole.offsetLeft + plot.timeplot.getElement().offsetLeft;
			var rightPos = plot.rightFlagPole.offsetLeft + plot.timeplot.getElement().offsetLeft;
			var rW = rightPos - leftPos;
			var pW = plot.canvas.width;
			var pL = plot.timeplot.getElement().offsetLeft;

			var handleTop = top + Math.floor(plot.gui.timeplotDiv.offsetHeight / 2 - plot.leftHandle.offsetHeight / 2);
			plot.leftHandle.style.visibility = "visible";
			plot.rightHandle.style.visibility = "visible";
			plot.leftHandle.style.left = (leftPos - plot.leftHandle.offsetWidth / 2) + "px";
			plot.rightHandle.style.left = (rightPos - plot.rightHandle.offsetWidth + 1 + plot.rightHandle.offsetWidth / 2) + "px";
			plot.leftHandle.style.top = handleTop + "px";
			plot.rightHandle.style.top = handleTop + "px";
			if (rightPos == leftPos) {
				plot.rightHandle.style.visibility = "hidden";
				plot.leftHandle.style.backgroundImage = "url(" + GeoTemConfig.path + "mergedHandle.png" + ")";
			} else {
				plot.leftHandle.style.backgroundImage = "url(" + GeoTemConfig.path + "leftHandle.png" + ")";
			}
			plot.cancelButton.style.visibility = "visible";
			plot.cancelButton.style.top = top + "px";

			if (rW > plot.cancelButton.offsetWidth) {
				plot.cancelButton.style.left = (left + rightPos - plot.cancelButton.offsetWidth) + "px";
			} else {
				plot.cancelButton.style.left = (left + rightPos) + "px";
			}
			var tW = plot.toolbarAbsoluteDiv.offsetWidth;
			if (rW >= tW) {
				plot.toolbar.style.left = leftPos + "px";
				plot.toolbar.style.width = (rW + 1) + "px";
				plot.toolbarAbsoluteDiv.style.left = ((rW - tW) / 2) + "px";
			} else {
				plot.toolbar.style.left = (pL + plot.leftFlagPos * (pW - tW) / (pW - rW)) + "px";
				plot.toolbar.style.width = (tW + 2) + "px";
				plot.toolbarAbsoluteDiv.style.left = "0px";
			}
			plot.toolbar.style.top = (top + plot.timeplot.getElement().offsetHeight) + "px";
			plot.toolbar.style.visibility = "visible";
			plot.toolbarAbsoluteDiv.style.visibility = "visible";

		}
		var getAbsoluteLeft = function(div) {
			var left = 0;
			while (div) {
				left += div.offsetLeft;
				div = div.offsetParent;
			}
			return left;
		}
		var timeplotLeft = getAbsoluteLeft(plot.timeplot.getElement());

		var checkPolesForStyle = function(x) {
			if (plot.style == 'bars' && plot.leftFlagTime == plot.rightFlagTime) {
				var index = plot.tds.getSliceIndex(plot.leftFlagTime);
				var time1 = plot.leftFlagTime;
				var pos1 = plot.leftFlagPos;
				var time2, pos2;
				if (index == 0) {
					time2 = plot.tds.getSliceTime(index + 1);
				} else if (index == plot.tds.getSliceNumber() - 1) {
					time2 = plot.tds.getSliceTime(index - 1);
				} else {
					if (x < plot.leftFlagPos) {
						time2 = plot.tds.getSliceTime(index - 1);
					} else {
						time2 = plot.tds.getSliceTime(index + 1);
					}
				}
				pos2 = plot.timeGeometry.toScreen(time2);
				mapPositions(pos1, pos2, time1, time2);
			}
		}
		var startX, startY, multiplier;

		// mousemove function that causes moving selection of objects and toolbar divs
		var moveToolbar = function(start, actual) {
			var pixelShift = actual - start;
			if (plot.status == 2) {
				var newTime = getCorrelatedTime(startX + pixelShift);
				if (newTime == plot.mouseTempTime) {
					return;
				}
				plot.mouseTempTime = newTime;
				plot.mouseTempPos = plot.timeGeometry.toScreen(plot.mouseTempTime);
				mapPositions(plot.mouseDownPos, plot.mouseTempPos);
			} else if (plot.status == 3) {
				pixelShift *= multiplier;
				var plotPos = actual - timeplotLeft;
				if (plotPos <= plot.canvas.width / 2) {
					var newTime = getCorrelatedTime(startX + pixelShift);
					if (newTime == plot.leftFlagTime) {
						return;
					}
					plot.leftFlagTime = newTime;
					var diff = plot.leftFlagPos;
					plot.leftFlagPos = plot.timeGeometry.toScreen(plot.leftFlagTime);
					diff -= plot.leftFlagPos;
					plot.rightFlagTime = getCorrelatedTime(plot.rightFlagPos - diff);
					plot.rightFlagPos = plot.timeGeometry.toScreen(plot.rightFlagTime);
				} else {
					var newTime = getCorrelatedTime(startY + pixelShift);
					if (newTime == plot.rightFlagTime) {
						return;
					}
					plot.rightFlagTime = newTime;
					var diff = plot.rightFlagPos;
					plot.rightFlagPos = plot.timeGeometry.toScreen(plot.rightFlagTime);
					diff -= plot.rightFlagPos;
					plot.leftFlagTime = getCorrelatedTime(plot.leftFlagPos - diff);
					plot.leftFlagPos = plot.timeGeometry.toScreen(plot.leftFlagTime);
				}
			}
			checkPolesForStyle(actual - timeplotLeft);
			setRangeDivs();
			plot.timeSelection();
		}
		// fakes user interaction mouse move
		var playIt = function(start, actual, reset) {
			if (!plot.paused) {
				var pixel = plot.canvas.width / (plot.tds.timeSlices.length - 1 ) / 5;
				var wait = 20 * pixel;
				if (reset) {
					actual = 0;
				}
				moveToolbar(start, actual);
				if (plot.rightFlagPos >= plot.canvas.width) {
					reset = true;
					wait = 1000;
				} else {
					reset = false;
				}
				setTimeout(function() {
					playIt(start, actual + pixel, reset)
				}, wait);
			}
		}
		var setMultiplier = function() {
			var rangeWidth = plot.rightFlagPos - plot.leftFlagPos;
			var toolbarWidth = plot.toolbarAbsoluteDiv.offsetWidth;
			var plotWidth = plot.canvas.width;
			if (rangeWidth < toolbarWidth) {
				multiplier = (plotWidth - rangeWidth) / (plotWidth - toolbarWidth);
			} else {
				multiplier = 1;
			}
		}
		/**
		 * starts the animation
		 */
		this.play = function() {
			if (this.leftFlagPos == null) {
				return;
			}
			plot.paused = false;
			plot.gui.updateAnimationButtons(2);
			plot.status = 3;
			setMultiplier();
			startX = plot.leftFlagPos;
			startY = plot.rightFlagPos;
			var position = Math.round(plot.leftFlagPos);
			playIt(position, position + 1, false);
		}
		/**
		 * stops the animation
		 */
		this.stop = function() {
			plot.paused = true;
			plot.status = 0;
			plot.gui.updateAnimationButtons(1);
		}
		// triggers the mousemove function to move the range and toolbar
		var toolbarEvent = function(evt) {
			var left = GeoTemConfig.getMousePosition(evt).left;
			document.onmousemove = function(evt) {
				moveToolbar(left, GeoTemConfig.getMousePosition(evt).left);
				if (plot.popup) {
					plot.popup.reset();
				}
			}
		}
		var initializeLeft = function() {
			plot.mouseDownTime = plot.rightFlagTime;
			plot.mouseTempTime = plot.leftFlagTime;
			plot.mouseDownPos = plot.timeGeometry.toScreen(plot.mouseDownTime);
			startX = plot.leftFlagPos;
		}
		var initializeRight = function() {
			plot.mouseDownTime = plot.leftFlagTime;
			plot.mouseTempTime = plot.rightFlagTime;
			plot.mouseDownPos = plot.timeGeometry.toScreen(plot.mouseDownTime);
			startX = plot.rightFlagPos;
		}
		var initializeDrag = function() {
			startX = plot.leftFlagPos;
			startY = plot.rightFlagPos;
			setMultiplier();
		}
		var checkBorders = function() {
			if (plot.style == 'bars' && plot.mouseUpTime == plot.mouseDownTime) {
				var index = plot.tds.getSliceIndex(plot.mouseUpTime);
				if (index == 0) {
					plot.mouseUpTime = plot.tds.getSliceTime(index + 1);
				} else if (index == plot.tds.getSliceNumber() - 1) {
					plot.mouseUpTime = plot.tds.getSliceTime(index - 1);
				} else {
					if (plot.x < plot.leftFlagPos) {
						plot.mouseUpTime = plot.tds.getSliceTime(index - 1);
					} else {
						plot.mouseUpTime = plot.tds.getSliceTime(index + 1);
					}
				}
			}
		}
		// handles mousedown on left handle
		this.leftHandle.onmousedown = function(evt) {
			if (plot.status != 2) {

				initializeLeft();
				plot.status = 2;
				toolbarEvent(evt);
				document.onmouseup = function() {
					document.onmousemove = null;
					document.onmouseup = null;
					plot.stop();
				}
			}
		}
		// handles mousedown on right handle
		this.rightHandle.onmousedown = function(evt) {
			if (plot.status != 2) {
				initializeRight();
				plot.status = 2;
				toolbarEvent(evt);
				document.onmouseup = function() {
					document.onmousemove = null;
					document.onmouseup = null;
					plot.stop();
				}
			}
		}
		// handles mousedown on drag button
		this.dragButton.onmousedown = function(evt) {
			if (plot.status != 3) {
				plot.status = 3;
				initializeDrag();
				toolbarEvent(evt);
				document.onmouseup = function() {
					document.onmousemove = null;
					document.onmouseup = null;
					plot.stop();
				}
			}
		}
		// handles mousedown-Event on timeplot
		var mouseDownHandler = function(elmt, evt, target) {
			if (plot.dataSources.length > 0) {

				plot.x = Math.round(SimileAjax.DOM.getEventRelativeCoordinates(evt, plot.canvas).x);
				if (plot.status == 0) {
					var time = getCorrelatedTime(plot.x);
					if (plot.leftFlagPos != null && plot.popup && time >= plot.leftFlagTime && time <= plot.rightFlagTime) {
						var x = plot.leftFlagPos + (plot.rightFlagPos - plot.leftFlagPos) / 2;
						var elements = [];
						for (var i = 0; i < plot.dataSources.length; i++) {
							elements.push([]);
						}
						for (var i = 0; i < plot.selectedObjects.length; i++) {
							if (plot.selectedObjects[i].value == 1) {
								for (var j = 0; j < plot.selectedObjects[i].objects.length; j++) {
									elements[j] = elements[j].concat(plot.selectedObjects[i].objects[j]);
								}
							}
						}
						var labels = [];
						for (var i = 0; i < elements.length; i++) {
							if (elements[i].length == 0) {
								continue;
							}
							var c = GeoTemConfig.getColor(i);
							var color = 'rgb(' + c.r0 + ',' + c.g0 + ',' + c.b0 + ')';
							var div = document.createElement("div");
							div.setAttribute('class', 'tagCloudItem');
							div.style.color = color;
							var label = {
								div : div,
								elements : elements[i]
							};
							var weight = 0;
							for (j in elements[i] ) {
								weight += elements[i][j].weight;
							}
							var fs = 2 * weight / 1000;
							if (fs > 2) {
								fs = 2;
							}
							div.style.fontSize = (1 + fs) + "em";
							div.style.textShadow = "0 0 0.4em black, 0 0 0.4em black, 0 0 0.4em black, 0 0 0.4em " + c.hex;
							if (weight == 1) {
								div.innerHTML = weight + " object";
							} else {
								div.innerHTML = weight + " objects";
							}
							var appendMouseFunctions = function(label, div, color) {
								div.onclick = function() {
									plot.popup.showLabelContent(label);
									div.style.textShadow = "0 0 0.4em black, 0 0 0.4em black, 0 0 0.4em black, 0 0 0.4em " + color;
								}
								div.onmouseover = function() {
									div.style.textShadow = "0 -1px " + color + ", 1px 0 " + color + ", 0 1px " + color + ", -1px 0 " + color;
								}
								div.onmouseout = function() {
									div.style.textShadow = "0 0 0.4em black, 0 0 0.4em black, 0 0 0.4em black, 0 0 0.4em " + color;
								}
							}
							appendMouseFunctions(label, div, c.hex);
							labels.push(label);
						}
						if (labels.length > 0) {
							plot.popup.createPopup(x + 20, 0, labels);
						}
					} else {
						plot.deselection();
						plot.status = 1;
						plot.mouseDownTime = time;
						plot.mouseTempTime = plot.mouseDownTime;
						plot.mouseDownPos = plot.timeGeometry.toScreen(plot.mouseDownTime);
						mapPositions(plot.mouseDownPos, plot.mouseDownPos, plot.mouseDownTime, plot.mouseDownTime);
						// handles mouseup-Event on timeplot
						document.onmouseup = function() {
							if (plot.status == 1) {
								plot.mouseUpTime = plot.mouseTempTime;
								plot.mouseUpPos = plot.timeGeometry.toScreen(plot.mouseUpTime);
								mapPositions(plot.mouseDownPos, plot.mouseUpPos, plot.mouseDownTime, plot.mouseUpTime);
								checkPolesForStyle(plot.x);
								setRangeDivs();
								plot.timeSelection();
								plot.gui.updateAnimationButtons(1);
								document.onmouseup = null;
								plot.status = 0;
							}
						}
					}
				}
			}
		}
		// handles mousemove-Event on timeplot
		var mouseMoveHandler = function(elmt, evt, target) {
			if (plot.dataSources.length > 0) {
				plot.x = Math.round(SimileAjax.DOM.getEventRelativeCoordinates(evt, plot.canvas).x);
				if (plot.status == 1) {
					plot.mouseTempTime = getCorrelatedTime(plot.x);
					plot.mouseTempPos = plot.timeGeometry.toScreen(plot.mouseTempTime);
					mapPositions(plot.mouseDownPos, plot.mouseTempPos, plot.mouseDownTime, plot.mouseTempTime);
					checkPolesForStyle(plot.x);
					setRangeDivs();
				}
			}
		}
		// handles mouseout-Event on timeplot
		var mouseOutHandler = function(elmt, evt, target) {
			if (plot.dataSources.length > 0) {
				var x = Math.round(SimileAjax.DOM.getEventRelativeCoordinates(evt, plot.canvas).x);
				var y = Math.round(SimileAjax.DOM.getEventRelativeCoordinates(evt, plot.canvas).y);
				if (x > plot.canvas.width - 2 || isNaN(x) || x < 2) {
					plot.timeHighlight(true);
					plot.highlightedSlice = undefined;
				} else if (y > plot.canvas.height - 2 || isNaN(y) || y < 2) {
					plot.timeHighlight(true);
					plot.highlightedSlice = undefined;
				}
			}
		}
		// handles mouse(h)over-Event on timeplot
		var mouseHoverHandler = function(elmt, evt, target) {
			if (plot.dataSources.length > 0) {
				var x = Math.round(SimileAjax.DOM.getEventRelativeCoordinates(evt, plot.canvas).x);
				var time = getCorrelatedTime(x);
				if (time == undefined) {
					return;
				}
				var highlightSlice;
				var slices = plot.tds.timeSlices;
				var index = plot.tds.getSliceIndex(time);
				if (plot.style == 'graph') {
					highlightSlice = slices[index];
				}
				if (plot.style == 'bars') {
					var pos = plot.timeGeometry.toScreen(time);
					if (x < pos && index > 0) {
						highlightSlice = slices[index - 1];
					} else {
						highlightSlice = slices[index];
					}
				}
				if (plot.highlightedSlice == undefined || plot.highlightedSlice != highlightSlice) {
					plot.highlightedSlice = highlightSlice;
					plot.timeHighlight(false);
				}
			}
		}

		this.redrawPlot = function() {
			plot.clearTimeplot();
			plot.tds.reset(this.timeGeometry);
			plot.timeplot._prepareCanvas();
			plot.timeplot.repaint();
			if (plot.leftFlagPos != null) {
				plot.leftFlagPos = getCorrelatedPosition(plot.leftFlagTime);
				plot.rightFlagPos = getCorrelatedPosition(plot.rightFlagTime);
				setRangeDivs();
			} else {
				plot.displayOverlay();
			}
			plot.initLabels([]);
			plot.updateOverview();
		}

		this.resetOpacityPlots = function() {
			var plots = plot.timeplot._plots;
			for ( var i = 0; i < plots.length; i++) {
				plots[i]._opacityCanvas.width = this.canvas.width;
				plots[i]._opacityCanvas.height = this.canvas.height;
				if( plot.leftFlagTime != null ){
					plots[i].fullOpacityPlot(plot.leftFlagTime, plot.rightFlagTime, plot.leftFlagPos, plot.rightFlagPos, GeoTemConfig.getColor(i));
				}
			}
		}

		/**
		 * handles zoom of the timeplot
		 * @param {int} delta the change of zoom
		 * @param {Date} time a time that corresponds to a slice, that was clicked
		 */
		/*
		this.zoom = function(delta,time){
		if( this.eventSources.length == 0 ){
		if( GeoTemConfig.timeZoom ){
		this.zoomSlider.setValue(0);
		}
		return false;
		}
		if( time == null ){
		time = getCorrelatedTime(this.canvas.width/2);
		}
		if( this.tds.setZoom(delta,time,this.leftFlagTime,this.rightFlagTime) ){
		this.redrawPlot();
		}
		if( GeoTemConfig.timeZoom ){
		this.zoomSlider.setValue(this.tds.getZoom());
		}
		return true;
		}
		*/

		// handles mousewheel event on the timeplot
		var mouseWheelHandler = function(elmt, evt, target) {
			if (evt.preventDefault) {
				evt.preventDefault();
			}
			if (plot.dataSources.length == 0) {
				return;
			}
			var delta = 0;
			if (!evt)
				evt = window.event;
			if (evt.wheelDelta) {
				delta = evt.wheelDelta / 120;
				if (window.opera)
					delta = -delta;
			} else if (evt.detail) {
				delta = -evt.detail / 3;
			}
			if (delta) {
				var x = Math.round(SimileAjax.DOM.getEventRelativeCoordinates(evt, plot.canvas).x);
				var time = getCorrelatedTime(x);
				plot.zoom(delta, time);
			}
		}
		var timeplotElement = this.timeplot.getElement();
		SimileAjax.DOM.registerEvent(timeplotElement, "mousedown", mouseDownHandler);
		SimileAjax.DOM.registerEvent(timeplotElement, "mousemove", mouseMoveHandler);
		SimileAjax.DOM.registerEvent(timeplotElement, "mousemove", mouseHoverHandler);
		SimileAjax.DOM.registerEvent(timeplotElement, "mouseout", mouseOutHandler);
		if (GeoTemConfig.mouseWheelZoom) {
			//SimileAjax.DOM.registerEvent(timeplotElement, "mousewheel", mouseWheelHandler);
		}

		this.gui.setHeight();

	},

	resetOverlay : function() {
		this.poles.style.visibility = "hidden";
		var plots = this.timeplot._plots;
		for (var i = 0; i < plots.length; i++) {
			for (var j = 0; j < plots[i].pins.length; j++) {
				plots[i].pins[j] = {
					height : 0,
					count : 0
				};
			}
		}
	},

	/**
	 * resets the timeplot to non selection status
	 */
	reset : function() {

		this.leftFlagPole.style.visibility = "hidden";
		this.rightFlagPole.style.visibility = "hidden";
		this.rangeBox.style.visibility = "hidden";
		this.leftHandle.style.visibility = "hidden";
		this.rightHandle.style.visibility = "hidden";
		this.toolbar.style.visibility = "hidden";
		this.toolbarAbsoluteDiv.style.visibility = "hidden";
		this.cancelButton.style.visibility = "hidden";

		var plots = this.timeplot._plots;
		for (var i = 0; i < plots.length; i++) {
			plots[i].opacityPlot.style.visibility = "hidden";
		}
		this.resetOverlay();
		this.filterBar.reset(false);

		var slices = this.tds.timeSlices;
		if (slices != undefined) {
			for (var i = 0; i < slices.length; i++) {
				slices[i].reset();
			}
		}

		this.status = 0;
		this.stop();
		this.gui.updateAnimationButtons(0);

		this.leftFlagPos = null;
		this.leftFlagTime = null;
		this.rightFlagPos = null;
		this.rightFlagTime = null;

		this.mouseDownTime = null;
		this.mouseUpTime = null;
		this.mouseTempTime = null;

		this.mouseDownPos = null;
		this.mouseUpPos = null;
		this.mouseTempPos = null;

		if (this.popup) {
			this.popup.reset();
			this.popupClickDiv.style.visibility = "hidden";
		}

	},

	/**
	 * sets a pole on the timeplot
	 * @param {Date} time the time of the specific timeslice
	 * @param {int[]} the number of selected elements per dataset
	 */
	displayOverlay : function() {
		this.poles.style.visibility = "visible";
		var cv = this.poles.getElementsByTagName("canvas")[0];
		cv.width = this.canvas.width;
		cv.height = this.canvas.height;
		if (!cv.getContext && G_vmlCanvasManager) {
			cv = G_vmlCanvasManager.initElement(cv);
		}
		var ctx = cv.getContext('2d');
		ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
		var plots = this.timeplot._plots;
		var slices = this.tds.timeSlices;
		for (var i = 0; i < slices.length; i++) {
			if (this.style == 'bars' && i + 1 == slices.length) {
				return;
			}
			if (slices[i].overlay() == 0) {
				continue;
			}
			var projStacks = slices[i].projStacks;
			var time = slices[i].date;
			var pos;
			if (this.style == 'graph') {
				pos = this.timeGeometry.toScreen(time);
			} else if (this.style == 'bars') {
				var x1 = this.timeGeometry.toScreen(time);
				var x2 = this.timeGeometry.toScreen(slices[i + 1].date);
				pos = (x1 + x2 ) / 2;
			}
			var heights = [];
			var h = 0;
			for (var j = 0; j < projStacks.length; j++) {
				var data = plots[j]._dataSource.getData();
				for (var k = 0; k < data.times.length; k++) {
					if (data.times[k].getTime() == time.getTime()) {
						var height = plots[j]._valueGeometry.toScreen(plots[j]._dataSource.getData().values[k]) * projStacks[j].overlay / projStacks[j].value;
						heights.push(height);
						plots[j].pins[i] = {
							height : height,
							count : projStacks[j].overlay
						};
						if (height > h) {
							h = height;
						}
						break;
					}
				}
			}
			ctx.fillStyle = "rgb(102,102,102)";
			ctx.beginPath();
			ctx.rect(pos - 1, this.canvas.height - h, 2, h);
			ctx.fill();
			for (var j = 0; j < heights.length; j++) {
				if (heights[j] > 0) {
					var color = GeoTemConfig.getColor(j);
					ctx.fillStyle = "rgba(" + color.r1 + "," + color.g1 + "," + color.b1 + ",0.6)";
					ctx.beginPath();
					ctx.arc(pos, this.canvas.height - heights[j], 2.5, 0, Math.PI * 2, true);
					ctx.closePath();
					ctx.fill();
				}
			}
		}
	},

	/**
	 * updates the timeplot by displaying place poles, after a selection had been executed in another widget
	 */
	highlightChanged : function(timeObjects) {
		if( !GeoTemConfig.highlightEvents ){
			return;
		}
		this.resetOverlay();
		if (this.selection.valid()) {
			if (!this.selection.equal(this)) {
				this.tds.setOverlay(GeoTemConfig.mergeObjects(timeObjects, this.selection.getObjects(this)));
			} else {
				this.tds.setOverlay(timeObjects);
			}
		} else {
			this.tds.setOverlay(timeObjects);
		}
		this.displayOverlay();
	},

	/**
	 * updates the timeplot by displaying place poles, after a selection had been executed in another widget
	 */
	selectionChanged : function(selection) {
		if( !GeoTemConfig.selectionEvents ){
			return;
		}
		this.reset();
		this.selection = selection;
		this.tds.setOverlay(selection.objects);
		this.displayOverlay();
	},

	/**
	 * returns the approximate left position of a slice inside the overview representation
	 * @param {Date} time time of the slice
	 */
	getOverviewLeft : function(time) {
		var w = this.overview.offsetWidth;
		var s = this.tds.earliest().getTime();
		var e = this.tds.latest().getTime();
		var t = time.getTime();
		return Math.round(w * (t - s) / (e - s));
	},

	/**
	 * visualizes the overview div (shows viewable part of zoomed timeplot)
	 */
	initOverview : function() {
		var labels = this.timeGeometry._grid;
		if (labels.length == 0) {
			var plot = this;
			setTimeout(function() {
				plot.initOverview();
			}, 10);
			return;
		}

		this.overview.style.width = this.canvas.width + "px";
		var left = this.gui.timeplotDiv.offsetLeft;
		this.overview.innerHTML = "";
		this.overview.style.left = left + "px";

		this.overviewRange = document.createElement("div");
		this.overviewRange.setAttribute('class', 'overviewRange');
		this.overview.appendChild(this.overviewRange);

		for (var i = 0; i < labels.length; i++) {
			var label = document.createElement("div");
			label.setAttribute('class', 'overviewLabel');
			label.innerHTML = labels[i].label;
			label.style.left = Math.floor(labels[i].x) + "px";
			this.overview.appendChild(label);
		}

		this.updateOverview();
	},

	/**
	 * visualizes the labels of the timeplot
	 */
	initLabels : function(labels) {
		if (labels.length == 0) {
			labels = this.timeGeometry._grid;
			if (labels.length == 0) {
				var plot = this;
				setTimeout(function() {
					plot.initLabels([]);
				}, 10);
				return;
			}
		}
		this.plotLabels.style.width = this.canvas.width + "px";
		var left = this.gui.timeplotDiv.offsetLeft;
		this.plotLabels.style.left = left + "px";
		this.plotLabels.innerHTML = "";
		for (var i = 0; i < labels.length; i++) {
			var label = document.createElement("div");
			label.setAttribute('class', 'plotLabel');
			label.innerHTML = labels[i].label;
			label.style.left = Math.floor(labels[i].x) + "px";
			this.plotLabels.appendChild(label);
		}
	},

	/**
	 * updates the overview div
	 */
	updateOverview : function() {
		if (this.tds.getZoom() > 0) {
			this.plotLabels.style.visibility = "hidden";
			this.timeGeometry._hideLabels = false;
			this.overview.style.visibility = "visible";
			this.shiftLeft.style.visibility = "visible";
			this.shiftRight.style.visibility = "visible";
			var left = this.getOverviewLeft(this.tds.timeSlices[this.tds.leftSlice].date);
			var right = this.getOverviewLeft(this.tds.timeSlices[this.tds.rightSlice].date);
			this.overviewRange.style.left = left + "px";
			this.overviewRange.style.width = (right - left) + "px";
		} else {
			this.timeGeometry._hideLabels = true;
			this.plotLabels.style.visibility = "visible";
			this.overview.style.visibility = "hidden";
			this.shiftLeft.style.visibility = "hidden";
			this.shiftRight.style.visibility = "hidden";
		}
	},

	/**
	 * returns the time slices which are created by the extended data source
	 */
	getSlices : function() {
		return this.tds.timeSlices;
	},

	timeSelection : function() {
		var slices = this.tds.timeSlices;
		var ls, rs;
		for (var i = 0; i < slices.length; i++) {
			if (slices[i].date.getTime() == this.leftFlagTime.getTime())
				ls = i;
			if (slices[i].date.getTime() == this.rightFlagTime.getTime()) {
				if (this.style == 'graph') {
					rs = i;
				}
				if (this.style == 'bars') {
					rs = i - 1;
				}
			}
		}
		var selectedObjects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++) {
			selectedObjects.push([]);
		}
		for (var i = 0; i < slices.length; i++) {
			if (i >= ls && i <= rs) {
				for (var j in slices[i].stacks ) {
					selectedObjects[j] = selectedObjects[j].concat(slices[i].stacks[j].elements);
				}
			}
		}
		this.selection = new Selection(selectedObjects, this);
		this.core.triggerSelection(this.selection);
		this.filterBar.reset(true);
	},

	deselection : function() {
		this.reset();
		this.selection = new Selection();
		this.core.triggerSelection(this.selection);
	},

	filtering : function() {
		for (var i = 0; i < this.datasets.length; i++) {
			this.datasets[i].objects = this.selection.objects[i];
		}
		this.core.triggerRefining(this.datasets);
	},

	inverseFiltering : function() {
		var slices = this.tds.timeSlices;
		var ls, rs;
		for (var i = 0; i < slices.length; i++) {
			if (slices[i].date.getTime() == this.leftFlagTime.getTime())
				ls = i;
			if (slices[i].date.getTime() == this.rightFlagTime.getTime()) {
				if (this.style == 'graph') {
					rs = i;
				}
				if (this.style == 'bars') {
					rs = i - 1;
				}
			}
		}
		var selectedObjects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++) {
			selectedObjects.push([]);
		}
		for (var i = 0; i < slices.length; i++) {
			if (i >= ls && i <= rs) {
				continue;
			}
			for (var j in slices[i].stacks ) {
				selectedObjects[j] = selectedObjects[j].concat(slices[i].stacks[j].elements);
			}
		}
		this.selection = new Selection(selectedObjects, this);
		this.filtering();
	},

	timeHighlight : function(undo) {
		if (this.status == 0) {
			var s = this.highlightedSlice;
			var timeObjects = [];
			for (var i = 0; i < this.tds.size(); i++) {
				timeObjects.push([]);
			}
			var add = true;
			if (this.leftFlagTime != null) {
				if (this.style == 'graph' && s.date >= this.leftFlagTime && s.date <= this.rightFlagTime) {
					add = false;
				}
				if (this.style == 'bars' && s.date >= this.leftFlagTime && s.date < this.rightFlagTime) {
					add = false;
				}
			}
			if (!undo && add) {
				for (var i in s.stacks ) {
					timeObjects[i] = timeObjects[i].concat(s.stacks[i].elements);
				}
			}
			this.core.triggerHighlight(timeObjects);
		}
	},

	timeRefining : function() {
		this.core.triggerRefining(this.selection.objects);
	},

	setStyle : function(style) {
		this.style = style;
	},

	drawLinearPlot : function() {
		if ( typeof this.valueGeometry != 'undefined') {			
			this.valueGeometry.actLinear();
			this.timeplot.repaint();
			this.resetOpacityPlots();
			this.displayOverlay();
		}
	},

	drawLogarithmicPlot : function() {
		if ( typeof this.valueGeometry != 'undefined') {
			this.valueGeometry.actLogarithmic();
			this.timeplot.repaint();
			this.resetOpacityPlots();
			this.displayOverlay();
		}
	}
}
