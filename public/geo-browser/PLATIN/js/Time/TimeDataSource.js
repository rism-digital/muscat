/*
* TimeDataSource.js
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
 * @class TimeDataSource, TimeSlice, TimeStack
 * implementation for aggregation of time items
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {JSON} options time configuration
 */
function TimeDataSource(options) {

	this.options = options;
	this.timeSlices = [];
	this.unit
	this.minDate
	this.maxDate
	this.eventSources
	this.events
	this.leftSlice
	this.rightSlice

	this.hashMapping

};

TimeDataSource.prototype = {

	findTimeUnits : function(granularity, timeUnit, pixels) {

		var time = SimileAjax.DateTime;
		this.availableUnits = [];
		var givenUnits = SimileAjax.DateTime.gregorianUnitLengths;
		for (var i = 0; i < givenUnits.length; i++) {
			if (granularity > i) {
				continue;
			}
			var slices = 0;
			var t = new Date(this.minDate.getTime());
			do {
				time.roundDownToInterval(t, i, undefined, 1, 0);
				slices++;
				time.incrementByInterval(t, i, undefined);
			} while( t.getTime() <= this.maxDate.getTime() && slices < pixels+2 );
			if (slices > 0 && slices <= pixels) {
				this.availableUnits.push({
					unit : i,
					slices : slices,
					label : SimileAjax.DateTime.Strings[GeoTemConfig.language][i]
				});
			}
		}
		var unitDiff200 = pixels + 1;
		for (var i = 0; i < this.availableUnits.length; i++) {
			var diff = Math.abs(this.availableUnits[i].slices - 200);
			if (diff < unitDiff200) {
				unitDiff200 = diff;
				this.unit = this.availableUnits[i].unit;
			}
		}

	},

	getUnitIndex : function() {
		for (var i = 0; i < this.availableUnits.length; i++) {
			if (this.unit == this.availableUnits[i].unit) {
				return i;
			}
		}
		return 0;
	},

	setTimeUnit : function(unit) {
		this.unit = unit;
		this.initializeSlices();
	},

	/**
	 * initializes the TimeDataSource
	 * @param {Timeplot.ColumnSource[]} dataSources the column sources corresponding to the data sets
	 * @param {Timeplot.DefaultEventSource[]} eventSources the event sources corresponding to the column sources
	 * @param {TimeObject[][]} timeObjects an array of time objects of different sets
	 * @param {SimileAjax.DateTime} granularity the time granularity of the given data
	 */
	initialize : function(dataSources, eventSources, timeObjects, granularity, timeUnit, pixels) {

		this.dataSources = dataSources;
		this.eventSources = eventSources;
		this.timeObjects = timeObjects;

		this.minDate = undefined;
		this.maxDate = undefined;
		this.hashMapping = [];
		this.projHashMapping = [];

		for (var i = 0; i < timeObjects.length; i++) {
			this.hashMapping.push([]);
			this.projHashMapping.push([]);
			for (var j = 0; j < timeObjects[i].length; j++) {
				var o = timeObjects[i][j];
				if (o.isTemporal) {
					var g = o.dates[this.options.timeIndex].granularity;
					//o.getTimeGranularity(this.options.timeIndex);
					if (g == null) {
						continue;
					}
					var time = o.dates[this.options.timeIndex].date;
					//o.getDate(this.options.timeIndex);
					if (this.minDate == undefined || time.getTime() < this.minDate.getTime()) {
						this.minDate = time;
					}
					if (this.maxDate == undefined || time.getTime() > this.maxDate.getTime()) {
						this.maxDate = time;
					}
				}
			}
		}

		if (this.minDate == undefined) {
			this.minDate = this.options.defaultMinDate;
			this.maxDate = this.options.defaultMaxDate;
		}

		this.findTimeUnits(granularity, timeUnit, pixels);
		this.initializeSlices();

	},

	initializeSlices : function() {
		for (var i = 0; i < this.dataSources.length; i++) {
			this.dataSources[i]._range = {
				earliestDate : null,
				latestDate : null,
				min : 0,
				max : 0
			};
		}
		this.timeSlices = [];
		var time = SimileAjax.DateTime;
		var t = new Date(this.minDate.getTime() - 0.9 * time.gregorianUnitLengths[this.unit]);
		do {
			time.roundDownToInterval(t, this.unit, undefined, 1, 0);
			var slice = new TimeSlice(SimileAjax.NativeDateUnit.cloneValue(t), this.timeObjects.length, this.dataSources.length);
			this.timeSlices.push(slice);
			time.incrementByInterval(t, this.unit, undefined);
		} while (t.getTime() <= this.maxDate.getTime() + 1.1 * time.gregorianUnitLengths[this.unit]);

		for (var i = 0; i < this.timeObjects.length; i++) {
			var projId = i;
			if( this.dataSources.length == 1 ){
				projId = 0;
			}
			for (var j = 0; j < this.timeObjects[i].length; j++) {
				var o = this.timeObjects[i][j];
				if (o.isTemporal) {
					var date = o.dates[this.options.timeIndex].date;
					//o.getDate(this.options.timeIndex);
					for (var k = 0; k < this.timeSlices.length - 1; k++) {
						var t1 = this.timeSlices[k].date.getTime();
						var t2 = this.timeSlices[k + 1].date.getTime();
						var stack = null, projStack = null;
						if (date >= t1 && date < t2) {
							stack = this.timeSlices[k].getStack(i);
							projStack = this.timeSlices[k].getProjStack(projId);
						}
						if (k == this.timeSlices.length - 2 && date >= t2) {
							stack = this.timeSlices[k + 1].getStack(i);
							projStack = this.timeSlices[k + 1].getProjStack(projId);
						}
						if (stack != null) {
							stack.addObject(o);
							projStack.addObject(o);
							this.hashMapping[i][o.index] = stack;
							this.projHashMapping[i][o.index] = projStack;
							break;
						}
					}
				}
			}
		}

		this.events = [];
		for (var i = 0; i < this.eventSources.length; i++) {
			var eventSet = [];
			for (var j = 0; j < this.timeSlices.length; j++) {
				var value = new Array("" + this.timeSlices[j].projStacks[i].value);
				eventSet.push({
					date : this.timeSlices[j].date,
					value : value
				});
			}
			this.eventSources[i].loadData(eventSet);
			this.events.push(eventSet);
		}

		this.leftSlice = 0;
		this.rightSlice = this.timeSlices.length - 1;

	},

	getSliceNumber : function() {
		return this.timeSlices.length;
	},

	/**
	 * computes the slice index corresponding to a given time
	 * @param {Date} time the given time
	 * @return the corresponding slice index
	 */
	getSliceIndex : function(time) {
		for (var i = 0; i < this.timeSlices.length; i++) {
			if (time == this.timeSlices[i].date) {
				return i;
			}
		}
	},

	/**
	 * returns the time of a specific time slice
	 * @param {int} time the given slice index
	 * @return the corresponding slice date
	 */
	getSliceTime : function(index) {
		return this.timeSlices[index].date;
	},

	/**
	 * shifts the actual zoomed range
	 * @param {int} delta the value to shift (negative for left shift, positive for right shift)
	 * @return boolean value, if the range could be shifted
	 */
	setShift : function(delta) {
		if (delta == 1 && this.leftSlice != 0) {
			this.leftSlice--;
			this.rightSlice--;
			return true;
		} else if (delta == -1 && this.rightSlice != this.timeSlices.length - 1) {
			this.leftSlice++;
			this.rightSlice++;
			return true;
		} else {
			return false;
		}
	},

	/**
	 * zooms the actual range
	 * @param {int} delta the value to zoom (negative for zoom out, positive for zoom in)
	 * @param {Date} time the corresponding time of the actual mouse position on the plot
	 * @param {Date} leftTime the time of the left border of a selected timerange or null
	 * @param {Date} rightTime the time of the right border of a selected timerange or null
	 * @return boolean value, if the range could be zoomed
	 */
	setZoom : function(delta, time, leftTime, rightTime) {
		var n1 = 0;
		var n2 = 0;
		var m = -1;
		if (delta > 0) {
			m = 1;
			if (leftTime != null) {
				n1 = this.getSliceIndex(leftTime) - this.leftSlice;
				n2 = this.rightSlice - this.getSliceIndex(rightTime);
			} else {
				slice = this.getSliceIndex(time);
				if (slice == this.leftSlice || slice == this.rightSlice) {
					return;
				}
				n1 = slice - 1 - this.leftSlice;
				n2 = this.rightSlice - slice - 1;
			}
		} else if (delta < 0) {

			n1 = this.leftSlice;
			n2 = this.timeSlices.length - 1 - this.rightSlice;
		}

		var zoomSlices = 2 * delta;
		if (Math.abs(n1 + n2) < Math.abs(zoomSlices)) {
			zoomSlices = n1 + n2;
		}

		if (n1 + n2 == 0) {
			return false;
		}

		var m1 = Math.round(n1 / (n1 + n2) * zoomSlices);
		var m2 = zoomSlices - m1;

		this.leftSlice += m1;
		this.rightSlice -= m2;

		return true;
	},

	/**
	 * resets the plots by loading data of actual zoomed range
	 */
	reset : function(timeGeometry) {
		for (var i = 0; i < this.eventSources.length; i++) {
			this.eventSources[i].loadData(this.events[i].slice(this.leftSlice, this.rightSlice + 1));
			if (i + 1 < this.eventSources.length) {
				timeGeometry._earliestDate = null;
				timeGeometry._latestDate = null;
			}

		}
	},

	/**
	 * Getter for actual zoom
	 * @return actual zoom value
	 */
	getZoom : function() {
		if (this.timeSlices == undefined) {
			return 0;
		}
		return Math.round((this.timeSlices.length - 3) / 2) - Math.round((this.rightSlice - this.leftSlice - 2) / 2);
	},

	/**
	 * Getter for date of the first timeslice
	 * @return date of the first timeslice
	 */
	earliest : function() {
		return this.timeSlices[0].date;
	},

	/**
	 * Getter for date of the last timeslice
	 * @return date of the last timeslice
	 */
	latest : function() {
		return this.timeSlices[this.timeSlices.length - 1].date;
	},

	setOverlay : function(timeObjects) {
		for (var i = 0; i < this.timeSlices.length; i++) {
			this.timeSlices[i].reset();
		}
		for (var j in timeObjects ) {
			for (var k in timeObjects[j] ) {
				var o = timeObjects[j][k];
				if (o.isTemporal) {
					if (o.getTimeGranularity(this.options.timeIndex) == null) {
						continue;
					}
					this.hashMapping[j][o.index].overlay += o.weight;
					this.projHashMapping[j][o.index].overlay += o.weight;
				}
			}
		}
	},

	size : function() {
		if (this.timeSlices.length == 0) {
			return 0;
		}
		return this.timeSlices[0].stacks.length;
	}
};

/**
 * small class that represents a time slice of the actual timeplot.
 * it has a specific date and contains its corrsponding data objects as well
 */
function TimeSlice(date, rows, projRows) {

	this.date = date;
	this.selected = false;

	this.stacks = [];
	this.projStacks = [];
	for (var i = 0; i < rows; i++) {
		this.stacks.push(new TimeStack());
	}
	for (var i = 0; i < projRows; i++) {
		this.projStacks.push(new TimeStack());
	}

	this.getStack = function(row) {
		return this.stacks[row];
	};

	this.getProjStack = function(row) {
		return this.projStacks[row];
	};

	this.reset = function() {
		for (var i in this.projStacks ) {
			this.stacks[i].overlay = 0;
			this.projStacks[i].overlay = 0;
		}
	};

	this.overlay = function() {
		var value = 0;
		for (var i in this.projStacks ) {
			if (this.projStacks[i].overlay > value) {
				value = this.projStacks[i].overlay;
			}
		}
		return value;
	};

};

/**
 * small class that represents a stack for a time slice which
 * holds items for different datasets for the specific time range
 */
function TimeStack() {

	this.overlay = 0;
	this.value = 0;
	this.elements = [];

	this.addObject = function(object) {
		this.elements.push(object);
		this.value += object.weight;
	};

};
