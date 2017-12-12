/*
* SimileTimeplotModify.js
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
 * Modified (overwritten) Simile Timeplot Functions
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
SimileAjax.DateTime.MILLISECOND = 0;
SimileAjax.DateTime.SECOND = 1;
SimileAjax.DateTime.MINUTE = 2;
SimileAjax.DateTime.HOUR = 3;
SimileAjax.DateTime.DAY = 4;
SimileAjax.DateTime.WEEK = 5;
SimileAjax.DateTime.MONTH = 6;
SimileAjax.DateTime.QUARTER = 7;
SimileAjax.DateTime.SEMESTER = 8;
SimileAjax.DateTime.YEAR = 9;
SimileAjax.DateTime.LUSTRUM = 10;
SimileAjax.DateTime.DECADE = 11;
SimileAjax.DateTime.HALFCENTURY = 12;
SimileAjax.DateTime.CENTURY = 13;
SimileAjax.DateTime.HALFMILLENNIUM = 14;
SimileAjax.DateTime.MILLENNIUM = 15;

SimileAjax.DateTime.Strings = {
	"en" : ["milliseconds", "seconds", "minutes", "hours", "days", "weeks", "months", "quarters", "semester", "years", "5 years", "decades", "50 years", "centuries", "500 years", "millenniums"],
	"de" : ["Millisekunden", "Sekunden", "Minuten", "Stunden", "Tage", "Wochen", "Monate", "Quartale", "Semester", "Jahre", "5 Jahre", "Dekaden", "50 Jahre", "Jahrhunderte", "500 Jahre", "Jahrtausende"]
};

SimileAjax.DateTime.gregorianUnitLengths = [];
(function() {
	var d = SimileAjax.DateTime;
	var a = d.gregorianUnitLengths;

	a[d.MILLISECOND] = 1;
	a[d.SECOND] = 1000;
	a[d.MINUTE] = a[d.SECOND] * 60;
	a[d.HOUR] = a[d.MINUTE] * 60;
	a[d.DAY] = a[d.HOUR] * 24;
	a[d.WEEK] = a[d.DAY] * 7;
	a[d.MONTH] = a[d.DAY] * 31;
	a[d.QUARTER] = a[d.DAY] * 91;
	a[d.SEMESTER] = a[d.DAY] * 182;
	a[d.YEAR] = a[d.DAY] * 365;
	a[d.LUSTRUM] = a[d.YEAR] * 5;
	a[d.DECADE] = a[d.YEAR] * 10;
	a[d.HALFCENTURY] = a[d.YEAR] * 50;
	a[d.CENTURY] = a[d.YEAR] * 100;
	a[d.HALFMILLENNIUM] = a[d.YEAR] * 500;
	a[d.MILLENNIUM] = a[d.YEAR] * 1000;
})();

SimileAjax.DateTime.roundDownToInterval = function(date, intervalUnit, timeZone, multiple, firstDayOfWeek) {
	timeZone = ( typeof timeZone == 'undefined') ? 0 : timeZone;
	var timeShift = timeZone * SimileAjax.DateTime.gregorianUnitLengths[SimileAjax.DateTime.HOUR];

	var date2 = new Date(date.getTime() + timeShift);
	var clearInDay = function(d) {
		d.setUTCMilliseconds(0);
		d.setUTCSeconds(0);
		d.setUTCMinutes(0);
		d.setUTCHours(0);
	};
	var clearInWeek = function(d) {
		clearInDay(d);
		var day = d.getDay();
		var millies = d.getTime();
		millies -= day * 1000 * 60 * 60 * 24;
		d.setTime(millies);
	};
	var clearInYear = function(d) {
		clearInDay(d);
		d.setUTCDate(1);
		d.setUTCMonth(0);
	};

	switch (intervalUnit) {
		case SimileAjax.DateTime.MILLISECOND:
			var x = date2.getUTCMilliseconds();
			date2.setUTCMilliseconds(x - (x % multiple));
			break;
		case SimileAjax.DateTime.SECOND:
			date2.setUTCMilliseconds(0);
			var x = date2.getUTCSeconds();
			date2.setUTCSeconds(x - (x % multiple));
			break;
		case SimileAjax.DateTime.MINUTE:
			date2.setUTCMilliseconds(0);
			date2.setUTCSeconds(0);
			var x = date2.getUTCMinutes();
			date2.setTime(date2.getTime() - (x % multiple) * SimileAjax.DateTime.gregorianUnitLengths[SimileAjax.DateTime.MINUTE]);
			break;
		case SimileAjax.DateTime.HOUR:
			date2.setUTCMilliseconds(0);
			date2.setUTCSeconds(0);
			date2.setUTCMinutes(0);
			var x = date2.getUTCHours();
			date2.setUTCHours(x - (x % multiple));
			break;
		case SimileAjax.DateTime.DAY:
			clearInDay(date2);
			break;
		case SimileAjax.DateTime.WEEK:
			clearInWeek(date2);
			break;
		case SimileAjax.DateTime.MONTH:
			clearInDay(date2);
			date2.setUTCDate(1);
			var x = date2.getUTCMonth();
			date2.setUTCMonth(x - (x % multiple));
			break;
		case SimileAjax.DateTime.QUARTER:
			clearInDay(date2);
			date2.setUTCDate(1);
			var x = date2.getUTCMonth();
			date2.setUTCMonth(x - (x % 3));
			break;
		case SimileAjax.DateTime.SEMESTER:
			clearInDay(date2);
			date2.setUTCDate(1);
			var x = date2.getUTCMonth();
			date2.setUTCMonth(x - (x % 6));
			break;
		case SimileAjax.DateTime.YEAR:
			clearInYear(date2);
			var x = date2.getUTCFullYear();
			date2.setUTCFullYear(x - (x % multiple));
			break;
		case SimileAjax.DateTime.LUSTRUM:
			clearInYear(date2);
			date2.setUTCFullYear(Math.floor(date2.getUTCFullYear() / 5) * 5);
			break;
		case SimileAjax.DateTime.DECADE:
			clearInYear(date2);
			date2.setUTCFullYear(Math.floor(date2.getUTCFullYear() / 10) * 10);
			break;
		case SimileAjax.DateTime.HALFCENTURY:
			clearInYear(date2);
			date2.setUTCFullYear(Math.floor(date2.getUTCFullYear() / 50) * 50);
			break;
		case SimileAjax.DateTime.CENTURY:
			clearInYear(date2);
			date2.setUTCFullYear(Math.floor(date2.getUTCFullYear() / 100) * 100);
			break;
		case SimileAjax.DateTime.HALFMILLENNIUM:
			clearInYear(date2);
			date2.setUTCFullYear(Math.floor(date2.getUTCFullYear() / 500) * 500);
			break;
		case SimileAjax.DateTime.MILLENNIUM:
			clearInYear(date2);
			date2.setUTCFullYear(Math.floor(date2.getUTCFullYear() / 1000) * 1000);
			break;
	}

	date.setTime(date2.getTime() - timeShift);
};

SimileAjax.DateTime.incrementByInterval = function(date, intervalUnit, timeZone) {
	timeZone = ( typeof timeZone == 'undefined') ? 0 : timeZone;

	var timeShift = timeZone * SimileAjax.DateTime.gregorianUnitLengths[SimileAjax.DateTime.HOUR];

	var date2 = new Date(date.getTime() + timeShift);

	switch (intervalUnit) {
		case SimileAjax.DateTime.MILLISECOND:
			date2.setTime(date2.getTime() + 1)
			break;
		case SimileAjax.DateTime.SECOND:
			date2.setTime(date2.getTime() + 1000);
			break;
		case SimileAjax.DateTime.MINUTE:
			date2.setTime(date2.getTime() + SimileAjax.DateTime.gregorianUnitLengths[SimileAjax.DateTime.MINUTE]);
			break;
		case SimileAjax.DateTime.HOUR:
			date2.setTime(date2.getTime() + SimileAjax.DateTime.gregorianUnitLengths[SimileAjax.DateTime.HOUR]);
			break;
		case SimileAjax.DateTime.DAY:
			date2.setUTCDate(date2.getUTCDate() + 1);
			break;
		case SimileAjax.DateTime.WEEK:
			date2.setUTCDate(date2.getUTCDate() + 7);
			break;
		case SimileAjax.DateTime.MONTH:
			date2.setUTCMonth(date2.getUTCMonth() + 1);
			break;
		case SimileAjax.DateTime.QUARTER:
			date2.setUTCMonth(date2.getUTCMonth() + 3);
			break;
		case SimileAjax.DateTime.SEMESTER:
			date2.setUTCMonth(date2.getUTCMonth() + 6);
			break;
		case SimileAjax.DateTime.YEAR:
			date2.setUTCFullYear(date2.getUTCFullYear() + 1);
			break;
		case SimileAjax.DateTime.LUSTRUM:
			date2.setUTCFullYear(date2.getUTCFullYear() + 5);
			break;
		case SimileAjax.DateTime.DECADE:
			date2.setUTCFullYear(date2.getUTCFullYear() + 10);
			break;
		case SimileAjax.DateTime.HALFCENTURY:
			date2.setUTCFullYear(date2.getUTCFullYear() + 50);
			break;
		case SimileAjax.DateTime.CENTURY:
			date2.setUTCFullYear(date2.getUTCFullYear() + 100);
			break;
		case SimileAjax.DateTime.HALFMILLENNIUM:
			date2.setUTCFullYear(date2.getUTCFullYear() + 500);
			break;
		case SimileAjax.DateTime.MILLENNIUM:
			date2.setUTCFullYear(date2.getUTCFullYear() + 1000);
			break;
	}
	date.setTime(date2.getTime() - timeShift);
};

SimileAjax.DateTime.getTimeLabel = function(unit, t) {
	var time = SimileAjax.DateTime;
	var second = t.getUTCSeconds();
	var minute = t.getUTCMinutes();
	var hour = t.getUTCHours();
	var day = t.getUTCDate();
	var month = t.getUTCMonth() + 1;
	var year = t.getUTCFullYear();
	switch(unit) {
		case time.SECOND:
			return hour + ":" + ((minute < 10) ? "0" : "") + minute + ":" + ((second < 10) ? "0" : "") + second;
		case time.MINUTE:
			return hour + ":" + ((minute < 10) ? "0" : "") + minute;
		case time.HOUR:
			return hour + ":00";
		case time.DAY:
		case time.WEEK:
		case time.MONTH:
		case time.QUARTER:
		case time.SEMESTER:
			return year + "-" + ((month < 10) ? "0" : "") + month + "-" + ((day < 10) ? "0" : "") + day;
		case time.YEAR:
		case time.LUSTRUM:
		case time.DECADE:
		case time.HALFCENTURY:
		case time.CENTURY:
		case time.HALFMILLENNIUM:
		case time.MILLENNIUM:
			return year;
	}
};

SimileAjax.DateTime.getTimeString = function(unit, t) {
	var time = SimileAjax.DateTime;
	switch(unit) {
		case time.MILLISECOND:
		case time.SECOND:
		case time.MINUTE:
		case time.HOUR:
			var m = t.getUTCMonth() + 1;
			var d = t.getUTCDate();
			var h = t.getUTCHours();
			var min = t.getUTCMinutes();
			var s = t.getUTCSeconds();
			return t.getUTCFullYear() + "-" + ((m < 10) ? "0" : "") + m + "-" + ((d < 10) ? "0" : "") + d + " " + ((h < 10) ? "0" : "") + h + ":" + ((min < 10) ? "0" : "") + min + ":" + ((s < 10) ? "0" : "") + s;
		case time.DAY:
		case time.WEEK:
		case time.MONTH:
		case time.QUARTER:
		case time.SEMESTER:
			var m = t.getUTCMonth() + 1;
			var d = t.getUTCDate();
			return t.getUTCFullYear() + "-" + ((m < 10) ? "0" : "") + m + "-" + ((d < 10) ? "0" : "") + d;
		case time.YEAR:
		case time.LUSTRUM:
		case time.DECADE:
		case time.HALFCENTURY:
		case time.CENTURY:
		case time.HALFMILLENNIUM:
		case time.MILLENNIUM:
			return t.getUTCFullYear();
	}
};

Timeplot.DefaultEventSource.prototype.loadData = function(events) {

	this._events.maxValues = new Array();
	this._events.removeAll();
	for (var i = 0; i < events.length; i++) {
		var event = events[i];
		var numericEvent = new Timeplot.DefaultEventSource.NumericEvent(event.date, event.value);
		this._events.add(numericEvent);
	}
	this._fire("onAddMany", []);

};

Timeplot._Impl.prototype.resetPlots = function(plotInfos) {

	this._plotInfos = plotInfos;
	this._painters = {
		background : [],
		foreground : []
	};
	this._painter = null;

	var timeplot = this;
	var painter = {
		onAddMany : function() {
			timeplot.update();
		},
		onClear : function() {
			timeplot.update();
		}
	}

	for ( i = this._plots.length; i > 0; i--) {
		this._plots[i - 1].opacityPlot.removeChild(this._plots[i - 1]._opacityCanvas);
		this._plots[i - 1].dispose();
		if (document.addEventListener) {
			this._containerDiv.removeEventListener("mousemove", this._plots[i - 1].mousemove, false);
			this._containerDiv.removeEventListener("mouseover", this._plots[i - 1].mouseover, false);
		} else if (document.attachEvent) {
			this._containerDiv.detachEvent("onmousemove", this._plots[i - 1].mousemove);
			this._containerDiv.detachEvent("onmouseover", this._plots[i - 1].mouseover);
		}
		delete this._plots[i - 1];
	}

	this._plots = [];

	for ( i = 0; i < this._plotInfos.length; i++) {
		var plot = new Timeplot.Plot(this, this._plotInfos[i]);
		var dataSource = plot.getDataSource();
		if (dataSource) {
			dataSource.addListener(painter);
		}
		this.addPainter("background", {
			context : plot.getTimeGeometry(),
			action : plot.getTimeGeometry().paint
		});
		this.addPainter("background", {
			context : plot.getValueGeometry(),
			action : plot.getValueGeometry().paint
		});
		this.addPainter("foreground", {
			context : plot,
			action : plot.paint
		});
		this._plots.push(plot);
		plot.initialize();
	}

};

Timeplot.DefaultTimeGeometry.prototype._calculateGrid = function() {
	var grid = [];

	var time = SimileAjax.DateTime;
	var u = this._unit;
	var p = this._period;

	if (p == 0)
		return grid;

	var periodUnit = -1;
	do {
		periodUnit++;
	} while (time.gregorianUnitLengths[periodUnit] < p);

	periodUnit--;

	var unit;
	if (periodUnit < time.DAY) {
		unit = time.HOUR;
	} else if (periodUnit < time.WEEK) {
		unit = time.DAY;
	} else if (periodUnit < time.QUARTER) {
		unit = time.WEEK;
	} else if (periodUnit < time.YEAR) {
		unit = time.MONTH;
	} else if (periodUnit < time.DECADE) {
		unit = time.YEAR;
	} else if (periodUnit < time.CENTURY) {
		unit = time.DECADE;
	} else if (periodUnit < time.HALFMILLENNIUM) {
		unit = time.CENTURY;
	} else if (periodUnit < time.MILLENNIUM) {
		unit = time.HALFMILLENNIUM;
	} else {
		unit = time.MILLENNIUM;
	}

	if (unit < this._granularity) {
		unit = this._granularity;
	}

	var t = u.cloneValue(this._earliestDate);
	var timeZone;
	do {
		time.roundDownToInterval(t, unit, timeZone, 1, 0);
		var x = this.toScreen(u.toNumber(t));
		var l = SimileAjax.DateTime.getTimeLabel(unit, t);
		if (x > 0) {
			grid.push({
				x : x,
				label : l
			});
		}
		time.incrementByInterval(t, unit, timeZone);
	} while (t.getTime() < this._latestDate.getTime());

	return grid;

};

//modified function to prevent from drawing left and right axis
Timeplot.DefaultValueGeometry.prototype.paint = function() {
	if (this._timeplot) {
		var ctx = this._canvas.getContext('2d');

		ctx.lineJoin = 'miter';

		// paint grid
		if (this._gridColor) {
			var gridGradient = ctx.createLinearGradient(0, 0, 0, this._canvas.height);
			gridGradient.addColorStop(0, this._gridColor.toHexString());
			gridGradient.addColorStop(0.3, this._gridColor.toHexString());
			gridGradient.addColorStop(1, "rgba(255,255,255,0.5)");

			ctx.lineWidth = this._gridLineWidth;
			ctx.strokeStyle = gridGradient;

			for (var i = 0; i < this._grid.length; i++) {
				var tick = this._grid[i];
				var y = Math.floor(tick.y) + 0.5;
				if ( typeof tick.label != "undefined") {
					if (this._axisLabelsPlacement == "left") {
						var div = this._timeplot.putText(this._id + "-" + i, tick.label, "timeplot-grid-label", {
							left : 4,
							bottom : y + 2,
							color : this._gridColor.toHexString(),
							visibility : "hidden"
						});
						this._labels.push(div);
					} else if (this._axisLabelsPlacement == "right") {
						var div = this._timeplot.putText(this._id + "-" + i, tick.label, "timeplot-grid-label", {
							right : 4,
							bottom : y + 2,
							color : this._gridColor.toHexString(),
							visibility : "hidden"
						});
						this._labels.push(div);
					}
					if (y + div.clientHeight < this._canvas.height + 10) {
						div.style.visibility = "visible";
						// avoid the labels that would overflow
					}
				}

				// draw grid
				ctx.beginPath();
				if (this._gridType == "long" || tick.label == 0) {
					ctx.moveTo(0, y);
					ctx.lineTo(this._canvas.width, y);
				} else if (this._gridType == "short") {
					if (this._axisLabelsPlacement == "left") {
						ctx.moveTo(0, y);
						ctx.lineTo(this._gridShortSize, y);
					} else if (this._axisLabelsPlacement == "right") {
						ctx.moveTo(this._canvas.width, y);
						ctx.lineTo(this._canvas.width - this._gridShortSize, y);
					}
				}
				ctx.stroke();
			}
		}
	}
};

//modified function to prevent from drawing hidden labels
Timeplot.DefaultTimeGeometry.prototype.paint = function() {
	if (this._canvas) {
		var unit = this._unit;
		var ctx = this._canvas.getContext('2d');

		var gradient = ctx.createLinearGradient(0, 0, 0, this._canvas.height);

		ctx.strokeStyle = gradient;
		ctx.lineWidth = this._gridLineWidth;
		ctx.lineJoin = 'miter';

		// paint grid
		if (this._gridColor) {
			gradient.addColorStop(0, this._gridColor.toString());
			gradient.addColorStop(1, "rgba(255,255,255,0.9)");
			for (var i = 0; i < this._grid.length; i++) {
				var tick = this._grid[i];
				var x = Math.floor(tick.x) + 0.5;
				if (this._axisLabelsPlacement == "top") {
					var div = this._timeplot.putText(this._id + "-" + i, tick.label, "timeplot-grid-label", {
						left : x + 4,
						top : 2,
						visibility : "hidden"
					});
					this._labels.push(div);
				} else if (this._axisLabelsPlacement == "bottom") {
					var div = this._timeplot.putText(this._id + "-" + i, tick.label, "timeplot-grid-label", {
						left : x + 4,
						bottom : 2,
						visibility : "hidden"
					});
					this._labels.push(div);
				}
				if (!this._hideLabels && x + div.clientWidth < this._canvas.width + 10) {
					div.style.visibility = "visible";
					// avoid the labels that would overflow
				}

				// draw separator
				ctx.beginPath();
				ctx.moveTo(x, 0);
				ctx.lineTo(x, this._canvas.height);
				ctx.stroke();
			}
		}
	}
};

Timeplot.Plot.prototype.getSliceNumber = function() {
	return this._dataSource.getData().times.length;
};

Timeplot.Plot.prototype.getSliceId = function(time) {
	var data = this._dataSource.getData();
	for (var k = 0; k < data.times.length; k++) {
		if (data.times[k].getTime() == time.getTime()) {
			return k;
		}
	}
	return null;
};

Timeplot.Plot.prototype.getSliceTime = function(index) {
	var data = this._dataSource.getData();
	if (0 <= index && index < data.times.length) {
		return data.times[index];
	}
	return null;
};

Timeplot.Plot.prototype.initialize = function() {
	if (this._dataSource && this._dataSource.getValue) {
		this._timeFlag = this._timeplot.putDiv("timeflag", "timeplot-timeflag");
		this._valueFlag = this._timeplot.putDiv(this._id + "valueflag", "timeplot-valueflag");
		this._pinValueFlag = this._timeplot.putDiv(this._id + "pinvalueflag", "timeplot-valueflag");
		var pin = document.getElementById(this._timeplot._id + "-" + this._id + "pinvalueflag");
		if (SimileAjax.Platform.browser.isIE && SimileAjax.Platform.browser.majorVersion < 9) {
			var cssText = "border: 1px solid " + this._plotInfo.lineColor.toString() + "; background-color: " + this._plotInfo.fillColor.toString() + ";";
			cssText = cssText.replace(/rgba\((\s*\d{1,3}),(\s*\d{1,3}),(\s*\d{1,3}),(\s*\d{1}|\s*\d{1}\.\d+)\)/g, 'rgb($1,$2,$3)');
			pin.style.setAttribute("cssText", cssText);
		} else {
			pin.style.border = "1px solid " + this._plotInfo.lineColor.toString();
			pin.style.backgroundColor = this._plotInfo.fillColor.toString();
		}
		this._valueFlagLineLeft = this._timeplot.putDiv(this._id + "valueflagLineLeft", "timeplot-valueflag-line");
		this._valueFlagLineRight = this._timeplot.putDiv(this._id + "valueflagLineRight", "timeplot-valueflag-line");
		this._pinValueFlagLineLeft = this._timeplot.putDiv(this._id + "pinValueflagLineLeft", "timeplot-valueflag-line");
		this._pinValueFlagLineRight = this._timeplot.putDiv(this._id + "pinValueflagLineRight", "timeplot-valueflag-line");
		if (!this._valueFlagLineLeft.firstChild) {
			this._valueFlagLineLeft.appendChild(SimileAjax.Graphics.createTranslucentImage(Timeplot.urlPrefix + "images/line_left.png"));
			this._valueFlagLineRight.appendChild(SimileAjax.Graphics.createTranslucentImage(Timeplot.urlPrefix + "images/line_right.png"));
		}
		if (!this._pinValueFlagLineLeft.firstChild) {
			this._pinValueFlagLineLeft.appendChild(SimileAjax.Graphics.createTranslucentImage(GeoTemConfig.path + "plot-line_left.png"));
			this._pinValueFlagLineRight.appendChild(SimileAjax.Graphics.createTranslucentImage(GeoTemConfig.path + "plot-line_right.png"));
		}
		this._valueFlagPole = this._timeplot.putDiv(this._id + "valuepole", "timeplot-valueflag-pole");

		var opacity = this._plotInfo.valuesOpacity;

		SimileAjax.Graphics.setOpacity(this._timeFlag, opacity);
		SimileAjax.Graphics.setOpacity(this._valueFlag, opacity);
		SimileAjax.Graphics.setOpacity(this._pinValueFlag, opacity);
		SimileAjax.Graphics.setOpacity(this._valueFlagLineLeft, opacity);
		SimileAjax.Graphics.setOpacity(this._valueFlagLineRight, opacity);
		SimileAjax.Graphics.setOpacity(this._pinValueFlagLineLeft, opacity);
		SimileAjax.Graphics.setOpacity(this._pinValueFlagLineRight, opacity);
		SimileAjax.Graphics.setOpacity(this._valueFlagPole, opacity);

		var plot = this;

		var mouseOverHandler = function(elmt, evt, target) {
			plot._timeFlag.style.visibility = "visible";
			plot._valueFlag.style.visibility = "visible";
			plot._pinValueFlag.style.visibility = "visible";
			plot._valueFlagLineLeft.style.visibility = "visible";
			plot._valueFlagLineRight.style.visibility = "visible";
			plot._pinValueFlagLineLeft.style.visibility = "visible";
			plot._pinValueFlagLineRight.style.visibility = "visible";
			plot._valueFlagPole.style.visibility = "visible";
			if (plot._plotInfo.showValues) {
				plot._valueFlag.style.display = "block";
				mouseMoveHandler(elmt, evt, target);
			}
		}
		var mouseOutHandler = function(elmt, evt, target) {
			plot._timeFlag.style.visibility = "hidden";
			plot._valueFlag.style.visibility = "hidden";
			plot._pinValueFlag.style.visibility = "hidden";
			plot._valueFlagLineLeft.style.visibility = "hidden";
			plot._valueFlagLineRight.style.visibility = "hidden";
			plot._pinValueFlagLineLeft.style.visibility = "hidden";
			plot._pinValueFlagLineRight.style.visibility = "hidden";
			plot._valueFlagPole.style.visibility = "hidden";
		}
		var day = 24 * 60 * 60 * 1000;
		var month = 30 * day;

		var mouseMoveHandler = function(elmt, evt, target) {
			if ( typeof SimileAjax != "undefined" && plot._plotInfo.showValues) {
				var c = plot._canvas;
				var x = Math.round(SimileAjax.DOM.getEventRelativeCoordinates(evt, plot._canvas).x);
				if (x > c.width)
					x = c.width;
				if (isNaN(x) || x < 0)
					x = 0;
				var t = plot._timeGeometry.fromScreen(x);
				if (t == 0) {// something is wrong
					plot._valueFlag.style.display = "none";
					return;
				}

				var v, validTime;
				if (plot.style == 'bars') {
					var time1 = plot._dataSource.getClosestValidTime(t);
					var x1 = plot._timeGeometry.toScreen(time1);
					var index_x1 = plot.getSliceId(time1);
					var time2;
					if (x < x1 && index_x1 > 0 || x >= x1 && index_x1 == plot.getSliceNumber() - 1) {
						time2 = plot.getSliceTime(index_x1 - 1);
					} else {
						time2 = plot.getSliceTime(index_x1 + 1);
					}
					var x2 = plot._timeGeometry.toScreen(time2);

					var t1 = new Date(time1);
					var t2 = new Date(time2);
					var unit = plot._timeGeometry.extendedDataSource.unit;
					var l;
					if (x1 < x2) {
						l = SimileAjax.DateTime.getTimeLabel(unit, t1) + '-' + SimileAjax.DateTime.getTimeLabel(unit, t2);
						validTime = time1;
					} else {
						l = SimileAjax.DateTime.getTimeLabel(unit, t2) + '-' + SimileAjax.DateTime.getTimeLabel(unit, t1);
						validTime = time2;
					}
					v = plot._dataSource.getValue(validTime);
					if (plot._plotInfo.roundValues)
						v = Math.round(v);
					plot._valueFlag.innerHTML = v;
					plot._timeFlag.innerHTML = l;
					x = (x1 + x2 ) / 2;
				} else if (plot.style == 'graph') {
					validTime = plot._dataSource.getClosestValidTime(t);
					x = plot._timeGeometry.toScreen(validTime);
					v = plot._dataSource.getValue(validTime);
					if (plot._plotInfo.roundValues)
						v = Math.round(v);
					plot._valueFlag.innerHTML = v;
					var t = new Date(validTime);
					var unit = plot._timeGeometry.extendedDataSource.unit;
					var l = SimileAjax.DateTime.getTimeLabel(unit, t);
					plot._timeFlag.innerHTML = l;
				}

				var tw = plot._timeFlag.clientWidth;
				var th = plot._timeFlag.clientHeight;
				var tdw = Math.round(tw / 2);
				var vw = plot._valueFlag.clientWidth;
				var vh = plot._valueFlag.clientHeight;
				var y = plot._valueGeometry.toScreen(v);

				if (x + tdw > c.width) {
					var tx = c.width - tdw;
				} else if (x - tdw < 0) {
					var tx = tdw;
				} else {
					var tx = x;
				}

				plot._timeplot.placeDiv(plot._valueFlagPole, {
					left : x,
					top : 0,
					height : c.height,
					display : "block"
				});
				plot._timeplot.placeDiv(plot._timeFlag, {
					left : tx - tdw,
					top : 0,
					display : "block"
				});

				var sliceId = plot.getSliceId(validTime);
				var pvw, pvh = 0, pinY;
				if (plot.pins[sliceId].count > 0) {
					plot._pinValueFlag.innerHTML = plot.pins[sliceId].count;
					pvw = plot._pinValueFlag.clientWidth;
					pvh = plot._pinValueFlag.clientHeight;
					pinY = plot.pins[sliceId].height;
				}
				var rightOverflow = x + vw + 14 > c.width;
				var leftOverflow = false;
				if (plot.pins[sliceId].count > 0) {
					if (x - pvw - 14 < 0) {
						leftOverflow = true;
					}
				}
				var shiftV, shiftP;
				if (plot.pins[sliceId].count > 0) {
					var cut = y - pinY < vh / 2 + pvh / 2;
					if ((leftOverflow || rightOverflow ) && cut) {
						shiftV = 0;
						shiftP = pvh;
					} else {
						shiftV = vh / 2;
						shiftP = pvh / 2;
					}
				} else {
					shiftV = vh / 2;
				}

				if (x + vw + 14 > c.width && y + vh / 2 + 4 > c.height) {
					plot._valueFlagLineLeft.style.display = "none";
					plot._timeplot.placeDiv(plot._valueFlagLineRight, {
						left : x - 14,
						bottom : y - 14,
						display : "block"
					});
					plot._timeplot.placeDiv(plot._valueFlag, {
						left : x - vw - 13,
						bottom : y - 13 - shiftV,
						display : "block"
					});
				} else if (x + vw + 14 > c.width && y + vh / 2 + 4 < c.height) {
					plot._valueFlagLineRight.style.display = "none";
					plot._timeplot.placeDiv(plot._valueFlagLineLeft, {
						left : x - 14,
						bottom : y,
						display : "block"
					});
					plot._timeplot.placeDiv(plot._valueFlag, {
						left : x - vw - 13,
						bottom : y + 13 - shiftV,
						display : "block"
					});
				} else if (x + vw + 14 < c.width && y + vh / 2 + 4 > c.height) {
					plot._valueFlagLineRight.style.display = "none";
					plot._timeplot.placeDiv(plot._valueFlagLineLeft, {
						left : x,
						bottom : y - 13,
						display : "block"
					});
					plot._timeplot.placeDiv(plot._valueFlag, {
						left : x + 13,
						bottom : y - 13 - shiftV,
						display : "block"
					});
				} else {
					plot._valueFlagLineLeft.style.display = "none";
					plot._timeplot.placeDiv(plot._valueFlagLineRight, {
						left : x,
						bottom : y,
						display : "block"
					});
					plot._timeplot.placeDiv(plot._valueFlag, {
						left : x + 13,
						bottom : y + 13 - shiftV,
						display : "block"
					});
				}

				if (plot.pins[sliceId].count > 0) {
					if (x - pvw - 14 < 0 && pinY + pvh + 4 > c.height) {
						plot._pinValueFlagLineLeft.style.display = "none";
						plot._timeplot.placeDiv(plot._pinValueFlagLineRight, {
							left : x,
							bottom : pinY,
							display : "block"
						});
						plot._timeplot.placeDiv(plot._pinValueFlag, {
							left : x + 13,
							bottom : pinY - 13 - shiftP,
							display : "block"
						});
					} else if (x - pvw - 14 < 0 && pinY + pvh + 4 < c.height) {
						plot._pinValueFlagLineLeft.style.display = "none";
						plot._timeplot.placeDiv(plot._pinValueFlagLineRight, {
							left : x,
							bottom : pinY,
							display : "block"
						});
						plot._timeplot.placeDiv(plot._pinValueFlag, {
							left : x + 13,
							bottom : pinY + 13 - shiftP,
							display : "block"
						});
					} else if (x - pvw - 14 >= 0 && pinY + pvh + 4 > c.height) {
						plot._pinValueFlagLineLeft.style.display = "none";
						plot._timeplot.placeDiv(plot._pinValueFlagLineRight, {
							left : x - 13,
							bottom : pinY - 13,
							display : "block"
						});
						plot._timeplot.placeDiv(plot._pinValueFlag, {
							left : x - 15 - pvw,
							bottom : pinY - 13 - shiftP,
							display : "block"
						});
					} else {
						plot._pinValueFlagLineRight.style.display = "none";
						plot._timeplot.placeDiv(plot._pinValueFlagLineLeft, {
							left : x - 14,
							bottom : pinY,
							display : "block"
						});
						plot._timeplot.placeDiv(plot._pinValueFlag, {
							left : x - pvw - 15,
							bottom : pinY + 13 - shiftP,
							display : "block"
						});
					}
				} else {
					plot._pinValueFlagLineLeft.style.display = "none";
					plot._pinValueFlagLineRight.style.display = "none";
					plot._pinValueFlag.style.display = "none";
				}

			}

		}
		var timeplotElement = this._timeplot.getElement();
		this.mouseover = SimileAjax.DOM.registerPlotEvent(timeplotElement, "mouseover", mouseOverHandler);
		this.mouseout = SimileAjax.DOM.registerPlotEvent(timeplotElement, "mouseout", mouseOutHandler);
		this.mousemove = SimileAjax.DOM.registerPlotEvent(timeplotElement, "mousemove", mouseMoveHandler);

		this.opacityPlot = this._timeplot.putDiv("opacityPlot" + this._timeplot._plots.length, "opacityPlot");
		SimileAjax.Graphics.setOpacity(this.opacityPlot, 50);
		//		this.opacityPlot.style.zIndex = this._timeplot._plots.length;
		this._timeplot.placeDiv(this.opacityPlot, {
			left : 0,
			bottom : 0,
			width : this._canvas.width,
			height : this._canvas.height
		});
		this._opacityCanvas = document.createElement("canvas");
		this.opacityPlot.appendChild(this._opacityCanvas);
		if (!this._opacityCanvas.getContext && G_vmlCanvasManager)
			this._opacityCanvas = G_vmlCanvasManager.initElement(this._opacityCanvas);
		this._opacityCanvas.width = this._canvas.width;
		this._opacityCanvas.height = this._canvas.height;
		this._opacityCanvas.style.position = 'absolute';
		this._opacityCanvas.style.left = '0px';
		this.opacityPlot.style.visibility = "hidden";

	}
};

SimileAjax.DOM.registerPlotEvent = function(elmt, eventName, handler) {
	var handler2 = function(evt) {
		evt = (evt) ? evt : ((event) ? event : null);
		if (evt) {
			var target = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
			if (target) {
				target = (target.nodeType == 1 || target.nodeType == 9) ? target : target.parentNode;
			}

			return handler(elmt, evt, target);
		}
		return true;
	}
	if (SimileAjax.Platform.browser.isIE) {
		elmt.attachEvent("on" + eventName, handler2);
	} else {
		elmt.addEventListener(eventName, handler2, false);
	}

	return handler2;
};

SimileAjax.DOM.getEventRelativeCoordinates = function(evt, elmt) {
	if (SimileAjax.Platform.browser.isIE) {
		var coords = SimileAjax.DOM.getPageCoordinates(elmt);
		return {
			x : evt.clientX - coords.left,
			y : evt.clientY - coords.top
		};
	} else {
		var coords = SimileAjax.DOM.getPageCoordinates(elmt);

		if ((evt.type == "DOMMouseScroll") && SimileAjax.Platform.browser.isFirefox && (SimileAjax.Platform.browser.majorVersion == 2)) {
			// Due to: https://bugzilla.mozilla.org/show_bug.cgi?id=352179

			return {
				x : evt.screenX - coords.left,
				y : evt.screenY - coords.top
			};
		} else {
			return {
				x : evt.pageX - coords.left,
				y : evt.pageY - coords.top
			};
		}
	}
};

SimileAjax.Graphics.setOpacity = function(elmt, opacity) {
	if (SimileAjax.Platform.browser.isIE) {
		elmt.style.filter = "alpha(opacity = " + opacity + ")";
	} else {
		var o = (opacity / 100).toString();
		elmt.style.opacity = o;
		elmt.style.MozOpacity = o;
	}
};

Timeplot.Plot.prototype.fullOpacityPlot = function(left, right, lp, rp, c) {

	var ctx = this._opacityCanvas.getContext('2d');

	ctx.clearRect(0, 0, this._canvas.width, this._canvas.height);
	ctx.lineWidth = this._plotInfo.lineWidth;
	ctx.lineJoin = 'miter';

	var h = this._canvas.height;
	ctx.fillStyle = this._plotInfo.lineColor.toString();

	var data = this._dataSource.getData();
	var times = data.times;
	var values = data.values;

	var first = true;
	ctx.beginPath();
	ctx.fillStyle = this._plotInfo.lineColor.toString();
	var lastX = 0, lastY = 0;
	for (var t = 0; t < times.length; t++) {
		if (!(times[t].getTime() < left.getTime() || times[t].getTime() > right.getTime())) {
			var x = this._timeGeometry.toScreen(times[t]);
			var y = this._valueGeometry.toScreen(values[t]);
			if (first) {
				ctx.moveTo(x, h);
				first = false;
			}
			if (this.style == 'bars') {
				ctx.lineTo(x, h - lastY);
			}
			ctx.lineTo(x, h - y);
			if (times[t].getTime() == right.getTime() || t == times.length - 1)
				ctx.lineTo(x, h);
			lastX = x;
			lastY = y;
		}
	}
	ctx.fill();

};

Timeplot._Impl.prototype.regularGrid = function() {

	var canvas = this.getCanvas();
	var ctx = canvas.getContext('2d');
	var gradient = ctx.createLinearGradient(0, 0, 0, canvas.height);
	gradient.addColorStop(0, "rgb(0,0,0)");
	gradient.addColorStop(1, "rgba(255,255,255,0.9)");
	ctx.strokeStyle = gradient;
	ctx.lineWidth = 0.5;
	ctx.lineJoin = 'miter';

	var xDist = canvas.width / 9;
	var positions = [];
	for (var i = 1; i < 9; i++) {
		var x = i * xDist;
		ctx.beginPath();
		ctx.moveTo(x, 0);
		ctx.lineTo(x, canvas.height);

		ctx.stroke();
		positions.push({
			label : '',
			x : x
		});
	}
	return positions;

};

Timeplot.Plot.prototype._plot = function() {
	var ctx = this._canvas.getContext('2d');
	var data = this._dataSource.getData();
	if (data) {
		var times = data.times;
		var values = data.values;
		var T = times.length;
		ctx.moveTo(0, 0);
		var lastX = 0, lastY = 0;
		for (var t = 0; t < T; t++) {
			var x = this._timeGeometry.toScreen(times[t]);
			var y = this._valueGeometry.toScreen(values[t]);
			if (t > 0 && (values[t - 1] > 0 || values[t] > 0 )) {
				if (this.style == 'graph') {
					ctx.lineTo(x, y);
				}
				if (this.style == 'bars') {
					if (values[t - 1] > 0) {
						ctx.lineTo(x, lastY);
					} else {
						ctx.moveTo(x, lastY);
					}
					ctx.lineTo(x, y);
				}
			} else {
				ctx.moveTo(x, y);
			}
			lastX = x;
			lastY = y;
		}
	}
};

SimileAjax.DOM.registerEvent = function(elmt, eventName, handler) {
	var handler2 = function(evt) {
		evt = (evt) ? evt : ((event) ? event : null);
		if (evt) {
			var target = (evt.target) ? evt.target : ((evt.srcElement) ? evt.srcElement : null);
			if (target) {
				target = (target.nodeType == 1 || target.nodeType == 9) ? target : target.parentNode;
			}

			return handler(elmt, evt, target);
		}
		return true;
	}
	if (SimileAjax.Platform.browser.isIE) {
		elmt.attachEvent("on" + eventName, handler2);
	} else {
		if (eventName == "mousewheel") {
			eventName = "DOMMouseScroll";
		}
		elmt.addEventListener(eventName, handler2, false);
	}
};

Timeplot._Impl.prototype._setUpright = function(ctx, canvas) {
	// excanvas+IE requires this to be done only once, ever; actual canvas
	// implementations reset and require this for each call to re-layout
	// modified: problem does not exist for IE9
	if (!SimileAjax.Platform.browser.isIE)
		this._upright = false;
	else if (SimileAjax.Platform.browser.majorVersion > 8)
		this._upright = false;
	if (!this._upright) {
		this._upright = true;
		ctx.translate(0, canvas.height);
		ctx.scale(1, -1);
	}
};

Timeplot._Impl.prototype._resizeCanvas = function() {
	var canvas = this.getCanvas();
	if (canvas.firstChild) {
		canvas.firstChild.style.width = canvas.clientWidth + 'px';
		canvas.firstChild.style.height = canvas.clientHeight + 'px';
	}
	for (var i = 0; i < this._plots.length; i++) {
		var opacityCanvas = this._plots[i]._opacityCanvas;
		if (opacityCanvas.firstChild) {
			opacityCanvas.firstChild.style.width = opacityCanvas.clientWidth + 'px';
			opacityCanvas.firstChild.style.height = opacityCanvas.clientHeight + 'px';
		}
	}
};

Timeplot._Impl.prototype.getWidth = function() {
	var canvas = this.getCanvas();
	if ( typeof canvas.width != 'undefined' && this._containerDiv.clientWidth == 0) {
		return canvas.width;
	}
	return this._containerDiv.clientWidth;
};

Timeplot._Impl.prototype.getHeight = function() {
	var canvas = this.getCanvas();
	if ( typeof canvas.height != 'undefined' && this._containerDiv.clientHeight == 0) {
		return canvas.height;
	}
	return this._containerDiv.clientHeight;
};

Timeplot._Impl.prototype._prepareCanvas = function() {
	var canvas = this.getCanvas();

	// using jQuery. note we calculate the average padding; if your
	// padding settings are not symmetrical, the labels will be off
	// since they expect to be centered on the canvas.
	var con = SimileAjax.jQuery(this._containerDiv);
	this._paddingX = (parseInt(con.css('paddingLeft')) + parseInt(con.css('paddingRight'))) / 2;
	this._paddingY = (parseInt(con.css('paddingTop')) + parseInt(con.css('paddingBottom'))) / 2;

	if (isNaN(this._paddingX)) {
		this._paddingX = 0;
	}
	if (isNaN(this._paddingY)) {
		this._paddingY = 0;
	}

	canvas.width = this.getWidth() - (this._paddingX * 2);
	canvas.height = this.getHeight() - (this._paddingY * 2);

	var ctx = canvas.getContext('2d');
	this._setUpright(ctx, canvas);
	ctx.globalCompositeOperation = 'source-over';
};
