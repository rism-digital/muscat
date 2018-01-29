/*
* FuzzyTimelineRangeSlider.js
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
 * @class FuzzyTimelineRangeSlider
 * Implementation for a fuzzy time-ranges slider
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {HTML object} parent div to append the FuzzyTimeline
 */
function FuzzyTimelineRangeSlider(parent) {

	var rangeSlider = this;
	
	this.parent = parent;
	this.options = parent.options;
	
	this.spans;
	
	this.datasets;
	
	this.sliderParentTable = this.parent.gui.sliderTable;
	var headerRow = $("<tr></tr>");
	var controlsRow = $("<tr></tr>");
	$(this.sliderParentTable).append(headerRow).append(controlsRow);
	
	headerRow.append("<td>Time start</td>");
	this.rangeStart = document.createElement("select");
	controlsRow.append($("<td></td>").append(this.rangeStart));
	
	headerRow.append("<td>Time unit</td>");
	this.rangeDropdown = document.createElement("select");
	controlsRow.append($("<td></td>").append(this.rangeDropdown));
	
	headerRow.append("<td>Scaling</td>");
	this.scalingDropdown = document.createElement("select");
	controlsRow.append($("<td></td>").append(this.scalingDropdown));
	$(this.scalingDropdown).append("<option>normal</option>");
	$(this.scalingDropdown).append("<option>logarithm</option>");
	$(this.scalingDropdown).append("<option>percentage</option>");
	$(this.scalingDropdown).change(function(eventObject){
		var scaleMode = $(rangeSlider.scalingDropdown).find("option:selected").text();
		rangeSlider.parent.changeScaleMode(scaleMode);
	});

	headerRow.append("<td>Animation</td>");
	this.startAnimation = document.createElement("div");
	$(this.startAnimation).addClass("smallButton playDisabled");
	this.pauseAnimation = document.createElement("div");
	$(this.pauseAnimation).addClass("smallButton pauseDisabled");
	controlsRow.append($("<td></td>").append(this.startAnimation).append(this.pauseAnimation));
	
	headerRow.append("<td>Dated Objects</td>");
	this.numberDatedObjects = 0;
	this.numberDatedObjectsDIV = document.createElement("div");
	$(this.numberDatedObjectsDIV).addClass("ddbElementsCount");
	controlsRow.append($("<td></td>").append(this.numberDatedObjectsDIV));
}

FuzzyTimelineRangeSlider.prototype = {

	initialize : function(datasets) {
		var rangeSlider = this;
		rangeSlider.datasets = datasets;

		//reset values
		rangeSlider.spans = [];
		rangeSlider.spanHash = [];

		//find smallest (most accurate) time-span
		var smallestSpan;
		rangeSlider.numberDatedObjects = 0;
		$(this.datasets).each(function(){
			$(this.objects).each(function(){
				var dataObject = this;
				var span;
				if (dataObject.isTemporal){
					rangeSlider.numberDatedObjects++;
					smallestSpan = moment.duration(1,'milliseconds');
				} else if (dataObject.isFuzzyTemporal){
					rangeSlider.numberDatedObjects++;
					span = moment.duration(dataObject.TimeSpanEnd-dataObject.TimeSpanBegin);
					if ( (typeof smallestSpan === 'undefined') || (span < smallestSpan))
						smallestSpan = span;
				}
			});
			if ((typeof smallestSpan !== 'undefined') && (smallestSpan.asMilliseconds() === 1))
				return false;
		});
		
		//show number of objects that have a time in header
		$(rangeSlider.numberDatedObjectsDIV).empty().append(rangeSlider.numberDatedObjects + " results");
		
		if (typeof smallestSpan === 'undefined')
			return;

		var fixedSpans = [
		    moment.duration(1, 'seconds'),
			moment.duration(1, 'minutes'),
			moment.duration(10, 'minutes'),
			moment.duration(15, 'minutes'),
			moment.duration(30, 'minutes'),
			moment.duration(1, 'hours'),
			moment.duration(5, 'hours'),
			moment.duration(10, 'hours'),
			moment.duration(12, 'hours'),
			moment.duration(1, 'days'),
			moment.duration(7, 'days'),
			moment.duration(1, 'weeks'),
			moment.duration(2, 'weeks'),
			moment.duration(1, 'months'),
			moment.duration(2, 'months'),
			moment.duration(3, 'months'),
			moment.duration(6, 'months'),
			moment.duration(1, 'years'),
			moment.duration(5, 'years'),
			moment.duration(10, 'years'),
			moment.duration(20, 'years'),
			moment.duration(25, 'years'),
			moment.duration(50, 'years'),
			moment.duration(100, 'years'),
			moment.duration(200, 'years'),
			moment.duration(250, 'years'),
			moment.duration(500, 'years'),
			moment.duration(1000, 'years'),
			moment.duration(2000, 'years'),
			moment.duration(2500, 'years'),
			moment.duration(5000, 'years'),
			moment.duration(10000, 'years'),
			];
		var overallSpan = rangeSlider.parent.overallMax-rangeSlider.parent.overallMin;
		//only add spans that are not too small for the data
		for (var i = 0; i < fixedSpans.length; i++){
			if (	(fixedSpans[i].asMilliseconds() > (smallestSpan.asMilliseconds() * 0.25)) &&
					(fixedSpans[i].asMilliseconds() < overallSpan)
					&&
					(
							rangeSlider.parent.options.showAllPossibleSpans ||
							((rangeSlider.parent.overallMax-rangeSlider.parent.overallMin)/fixedSpans[i]<rangeSlider.options.maxBars)
					))
				rangeSlider.spans.push(fixedSpans[i]);
		}
		
		$(rangeSlider.rangeDropdown).empty();
		
		$(rangeSlider.rangeDropdown).append("<option>continuous</option>");
		var index = 0;
		$(rangeSlider.spans).each(function(){
			var duration = this;
			if (duration < moment.duration(1,'second'))
				humanizedSpan = duration.milliseconds() + "ms";
			else if (duration < moment.duration(1,'minute'))
				humanizedSpan = duration.seconds() + "s";
			else if (duration < moment.duration(1,'hour'))
				humanizedSpan = duration.minutes() + "min";
			else if (duration < moment.duration(1,'day'))
				humanizedSpan = duration.hours() + "h";
			else if (duration < moment.duration(1,'month')){
				var days = duration.days();
				humanizedSpan = days + " day";
				if (days > 1)
					humanizedSpan += "s";
			} else if (duration < moment.duration(1,'year')){
				var months = duration.months();
				humanizedSpan = months + " month";
				if (months > 1)
					humanizedSpan += "s";
			} else {
				var years = duration.years();
				humanizedSpan = years + " year";
				if (years > 1)
					humanizedSpan += "s";
			}
			$(rangeSlider.rangeDropdown).append("<option index='"+index+"'>"+humanizedSpan+"</option>");
			index++;
		});

		$(rangeSlider.rangeDropdown).change(function( eventObject ){
			var handlePosition = $(rangeSlider.rangeDropdown).find("option:selected").first().attr("index");
			//if there is no index, "continuous" is selected - so the density plot will be drawn
			
			if (typeof handlePosition === "undefined"){
				rangeSlider.parent.switchViewMode("density");
			} else {
				rangeSlider.parent.switchViewMode("barchart");
			}
			
			rangeSlider.parent.slidePositionChanged(rangeSlider.spans[handlePosition]);
		});
			
		$(rangeSlider.rangeStart).empty();
		//add start of timeline selections
		//TODO: add Months/Days/etc., atm there are only years
		var starts = [];
		var overallMin = rangeSlider.parent.overallMin;
		var last = moment(overallMin).year();
		starts.push(last);
		for (i = 1;;i++){
			var date = moment(overallMin).year();
			date = date/Math.pow(10,i);
			if (Math.abs(date)<1)
				break;
			date = Math.floor(date);
			date = date*Math.pow(10,i);
			if (date != last)
				starts.push(date);
			last = date;
		}
		$(starts).each(function(){
			$(rangeSlider.rangeStart).append("<option>"+this+"</option>");				
		});

		$(rangeSlider.rangeStart).change(function( eventObject ){
			var handlePosition = rangeSlider.rangeStart.selectedIndex;
			var start = starts[handlePosition];
				
			rangeSlider.parent.overallMin = moment().year(start);
			$(rangeSlider.rangeDropdown).change();
		});

		$(rangeSlider.rangeDropdown).change();
		
		$(rangeSlider.startAnimation).click(function(){
			if ($(rangeSlider.startAnimation).hasClass("playEnabled")){
				$(rangeSlider.startAnimation).removeClass("playEnabled").addClass("playDisabled");
				$(rangeSlider.pauseAnimation).removeClass("pauseDisabled").addClass("pauseEnabled");
				
				rangeSlider.parent.startAnimation();
			}
		});

		$(rangeSlider.pauseAnimation).prop('disabled', true);
		$(rangeSlider.pauseAnimation).click(function(){
			if ($(rangeSlider.pauseAnimation).hasClass("pauseEnabled")){
				$(rangeSlider.startAnimation).removeClass("playDisabled").addClass("playEnabled");
				$(rangeSlider.pauseAnimation).removeClass("pauseEnabled").addClass("pauseDisabled");
				
				rangeSlider.parent.pauseAnimation();
			}
		});
	},
	
	triggerHighlight : function(columnElement) {

	},

	triggerSelection : function(columnElement) {

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
	
	show : function() {		
	},

	hide : function() {
	}
};
