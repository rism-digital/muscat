/*
* FuzzyTimelineWidget.js
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
 * @class FuzzyTimelineWidget
 * FuzzyTimelineWidget Implementation
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {WidgetWrapper} core wrapper for interaction to other widgets
 * @param {HTML object} div parent div to append the FuzzyTimeline widget div
 * @param {JSON} options user specified configuration that overwrites options in FuzzyTimelineConfig.js
 */
FuzzyTimelineWidget = function(core, div, options) {

	this.datasets;
	this.selected = undefined;
	this.overallMin;
	this.overallMax;
	
	this.core = core;
	this.core.setWidget(this);

	this.options = (new FuzzyTimelineConfig(options)).options;
	this.gui = new FuzzyTimelineGui(this, div, this.options);

	this.viewMode;
	this.density;
	this.rangeSlider;
	this.rangeBars;
	this.rangePiechart;
	this.spanHash = [];
	
	this.handles = [];
	this.zoomFactor = 1;
	
	this.scaleMode = "normal";
}

FuzzyTimelineWidget.prototype = {

	initWidget : function(data) {
		var fuzzyTimeline = this;
		
		delete fuzzyTimeline.overallMin;
		delete fuzzyTimeline.overallMax;
		
		$(fuzzyTimeline.gui.plotDiv).empty();
		$(fuzzyTimeline.gui.sliderTable).empty();
		delete fuzzyTimeline.rangeSlider;
		$(fuzzyTimeline.gui.rangePiechartDiv).empty();
		delete fuzzyTimeline.rangePiechart;

		fuzzyTimeline.switchViewMode("density");
		
		if ( (data instanceof Array) && (data.length > 0) )
		{
			fuzzyTimeline.datasets = data;
			
			$(fuzzyTimeline.datasets).each(function(){
				$(this.objects).each(function(){
					var datemin,datemax;
					if (this.isTemporal){
						//TODO: allow more than one date
						datemin = moment(this.dates[0].date);
						datemax = datemin;
					} else if (this.isFuzzyTemporal){
						//TODO: allow more than one date
						datemin = this.TimeSpanBegin;
						datemax = this.TimeSpanEnd;
					}
					
					if (typeof fuzzyTimeline.overallMin === "undefined")
						fuzzyTimeline.overallMin = datemin;
					if (typeof fuzzyTimeline.overallMax === "undefined")
						fuzzyTimeline.overallMax = datemax;
					
					if (fuzzyTimeline.overallMin > datemin)
						fuzzyTimeline.overallMin = datemin;
					if (fuzzyTimeline.overallMax < datemax)
						fuzzyTimeline.overallMax = datemax;
				});
			});
			
			fuzzyTimeline.rangeSlider = new FuzzyTimelineRangeSlider(fuzzyTimeline);
			fuzzyTimeline.rangeSlider.initialize(fuzzyTimeline.datasets);

			fuzzyTimeline.rangePiechart = new FuzzyTimelineRangePiechart(fuzzyTimeline, fuzzyTimeline.gui.rangePiechartDiv);
			fuzzyTimeline.rangePiechart.initialize(fuzzyTimeline.datasets);
		}
	},
	
	switchViewMode : function(viewMode){
		var fuzzyTimeline = this;
		if (viewMode !== fuzzyTimeline.viewMode){
			$(fuzzyTimeline.gui.plotDiv).empty();
			if (viewMode === "density"){
				fuzzyTimeline.density = new FuzzyTimelineDensity(fuzzyTimeline,fuzzyTimeline.gui.plotDiv);
			} else if (viewMode === "barchart"){
				fuzzyTimeline.rangeBars = new FuzzyTimelineRangeBars(fuzzyTimeline);
			}
			fuzzyTimeline.viewMode = viewMode;
		}
	},
	
	scaleData : function(data){
		var fuzzyTimeline = this;
		if (fuzzyTimeline.scaleMode == "normal"){
			return data;
		} else if (fuzzyTimeline.scaleMode == "logarithm"){
			for(var index in data){
				var val = data[index];
				if (val!=0){
					var sign = 1;
					if (val<0){
						sign = -1;
					}
					data[index] = sign*Math.log(Math.abs(data[index])+1);
				}	
			}
			return data;
		} else if (fuzzyTimeline.scaleMode == "percentage"){
			var overallCnt = 0;
			for(var index in data){
				var val = data[index];
				if (val > 0){
					overallCnt += val;
				}
			}
			//make 1 = 100%
			overallCnt = overallCnt/100;
			if (overallCnt != 0){
				for(var index in data){
					data[index] = (data[index])/overallCnt;	
				}
			}
			return data;
		}
	},
	
	changeScaleMode : function(scaleMode) {
		var fuzzyTimeline = this;
		fuzzyTimeline.scaleMode = scaleMode;
		fuzzyTimeline.drawFuzzyTimeline();
	},
	
	slidePositionChanged : function(spanWidth) {
		var fuzzyTimeline = this;
		fuzzyTimeline.spanWidth = spanWidth;
		fuzzyTimeline.drawFuzzyTimeline();
	},
	
	drawFuzzyTimeline : function(){
		var fuzzyTimeline = this;
		var datasets = fuzzyTimeline.datasets;
		if (fuzzyTimeline.viewMode === "density"){
			//redraw density plot
			fuzzyTimeline.density.drawDensityPlot(datasets);
			//select currently selected data (if there is any) 
			fuzzyTimeline.density.selectionChanged(fuzzyTimeline.selected);
		} else if (fuzzyTimeline.viewMode === "barchart"){
			//redraw range plot
			fuzzyTimeline.rangeBars.drawRangeBarChart(datasets,fuzzyTimeline.spanWidth);
			//select currently selected data (if there is any)
			fuzzyTimeline.rangeBars.selectionChanged(fuzzyTimeline.selected);
		}
	},

	highlightChanged : function(objects) {
		var fuzzyTimeline = this;
		if( !GeoTemConfig.highlightEvents ){
			return;
		}
		if ( (typeof objects === "undefined") || (objects.length == 0) ){
			return;
		}
		if (fuzzyTimeline.viewMode === "density")
			this.density.highlightChanged(objects);
		else if (fuzzyTimeline.viewMode === "barchart")
			this.rangeBars.highlightChanged(objects);
		
		fuzzyTimeline.rangePiechart.highlightChanged(objects);
	},

	selectionChanged : function(selection) {
		var fuzzyTimeline = this;
		if( !GeoTemConfig.selectionEvents ){
			return;
		}
		if ((typeof selection.objects !== "undefined")&&
			(selection.objects.length == GeoTemConfig.datasets.length)){
			var objectCount = 0;
			for (var i=0, il=selection.objects.length; i < il; i++){
				objectCount += selection.objects[i].length;
			}
			if (objectCount > 0){
				fuzzyTimeline.selected = selection.objects;
			} else {
				delete fuzzyTimeline.selected;
			}
		} else 
			delete fuzzyTimeline.selected;
		if (fuzzyTimeline.viewMode === "density")
			this.density.selectionChanged(fuzzyTimeline.selected);
		else if (fuzzyTimeline.viewMode === "barchart")
			this.rangeBars.selectionChanged(fuzzyTimeline.selected);
		
		if (selection.valid())
			fuzzyTimeline.rangePiechart.selectionChanged(fuzzyTimeline.selected);
		else
			fuzzyTimeline.rangePiechart.selectionChanged([]);
		
		//selections "overwrite" each other
		if (selection.widget != fuzzyTimeline)
			fuzzyTimeline.clearHandles();
	},
	
	buildSpanArray : function(spanWidth) {
		var spanArray = [];
		var tickStart = moment(this.overallMin);		 
		do{
			spanArray.push(moment(tickStart));
			tickStart.add(spanWidth);
		} while (tickStart <= this.overallMax);
		spanArray.push(moment(tickStart));
		
		this.spanHash.push({spanWidth:spanWidth,overallMin:moment(this.overallMin),spanArray:spanArray});
		return(spanArray);
	},
	
	getSpanArray : function(spanWidth){
		for (var i = 0; i < this.spanHash.length; i++){
			var element = this.spanHash[i];
			if (	((this.overallMin-element.overallMin)===0) &&
					((spanWidth-element.spanWidth)===0))
				return element.spanArray;
		}
		return this.buildSpanArray(spanWidth);
	},
	
	clearSpanArray : function(){
		this.spanHash = [];
	},
	
	getTicks : function(dataObject, spanWidth) {
		var datemin,datemax;
		if (dataObject.isTemporal){
			datemin = moment(dataObject.dates[0].date);
			datemax = datemin;
		} else if (dataObject.isFuzzyTemporal){
			datemin = dataObject.TimeSpanBegin;
			datemax = dataObject.TimeSpanEnd;
		} else{
			return;
		}
		
		if (typeof spanWidth._data === "undefined"){
			//This does only work with millisecond spans, as the length of years is (very) inaccurate.
			//(e.g. 100-0 = 99, 2000-1000 = 1001, 5000-0 = 5003, and so on and even more: duration(5000a) = 4932a)
			//So the time consuming loop below is needed for accurate dates, when years/months/days etc. are supplied
			var firstTick = Math.floor((datemin-this.overallMin)/spanWidth);
			var lastTick = Math.floor((datemax-this.overallMin)/spanWidth);
			//calculate how much the first (and last) tick and the time-span overlap
			var firstTickPercentage = 1;
			var lastTickPercentage = 1;
			if (firstTick != lastTick){
				var secondTickStart = this.overallMin+(firstTick+1)*spanWidth;
				var lastTickStart = this.overallMin+lastTick*spanWidth;
				firstTickPercentage = (secondTickStart-datemin)/spanWidth;
				lastTickPercentage = (datemax-lastTickStart)/spanWidth;
			}
			if (firstTickPercentage === 0){
				firstTick++;
				firstTickPercentage = 1;
			}
			if (lastTickPercentage === 0){
				lastTick--;
				lastTickPercentage = 1;
			}
		} else {
			var spanArray = this.getSpanArray(spanWidth);
			var firstTick, lastTick;
			var tickCount = 0;
			var tickStart = spanArray[0];
			var lastTickStart;
			do{
				lastTickStart = spanArray[tickCount];
				tickCount++;
				tickStart = spanArray[tickCount];
				if ( (typeof firstTick === "undefined") && (datemin < tickStart) ){
					firstTick = tickCount-1;
					firstTickPercentage = (tickStart - datemin)/spanWidth;
				}
				if ( (typeof lastTick === "undefined") && (datemax <= tickStart) ){
					lastTick = tickCount-1;
					lastTickPercentage = (datemax - lastTickStart)/spanWidth;
				}
			} while (tickStart < datemax);
			if (firstTick == lastTick){
				firstTickPercentage = 1;
				lastTickPercentage = 1;
			}
		}
		
		return({	firstTick:firstTick,
					lastTick:lastTick,
					firstTickPercentage:firstTickPercentage,
					lastTickPercentage:lastTickPercentage});
	},

	getObjects : function(dateStart, dateEnd) {
		var fuzzyTimeline = this;
		var searchDateStart, searchDateEnd;
		if (typeof dateStart !== "undefined")
			searchDateStart = moment(dateStart);
		if (typeof dateEnd !== "undefined")
			searchDateEnd = moment(dateEnd);
		
		var datasets = [];		
		$(fuzzyTimeline.datasets).each(function(){
			var objects = [];
			//check if we got "real" datasets, or just array of objects
			var datasetObjects = this;
			if (typeof this.objects !== "undefined")
				datasetObjects = this.objects;
			$(datasetObjects).each(function(){
				var datemin,datemax;
				var dataObject = this;
				if (dataObject.isTemporal){
					datemin = moment(dataObject.dates[0].date);
					datemax = datemin;
				} else if (dataObject.isFuzzyTemporal){
					datemin = dataObject.TimeSpanBegin;
					datemax = dataObject.TimeSpanEnd;
				} else{
					return;
				}
				
				if (typeof searchDateEnd === 'undefined'){
					if ( (datemin <= searchDateStart) && (datemax >= searchDateStart) )
						objects.push(this);
				} else {
					if ((datemin < searchDateEnd) && (datemax >= searchDateStart))
						objects.push(this);
				}
			});
			datasets.push(objects);
		});

		return(datasets);
	},
		
	triggerHighlight : function(highlightedObjects){
		var fuzzyTimeline = this;
		if (fuzzyTimeline.viewMode === "density")
			fuzzyTimeline.density.highlightChanged(highlightedObjects);
		else if (fuzzyTimeline.viewMode === "barchart")
			fuzzyTimeline.rangeBars.highlightChanged(highlightedObjects);
		
		fuzzyTimeline.core.triggerHighlight(highlightedObjects);		
	},
	
	triggerSelection : function(selectedObjects){
		var fuzzyTimeline = this;
		fuzzyTimeline.selected = selectedObjects;
		if (fuzzyTimeline.viewMode === "density")
			fuzzyTimeline.density.selectionChanged(selectedObjects);
		else if (fuzzyTimeline.viewMode === "barchart")
			fuzzyTimeline.rangeBars.selectionChanged(selectedObjects);
		
		selection = new Selection(selectedObjects);
		
		fuzzyTimeline.core.triggerSelection(selection);		
	},
	
	addHandle : function(x1,x2){
		var fuzzyTimeline = this;
		//make sure the interval is ordered correctly
		if (x2<x1){
			var temp = x1;
			x1 = x2;
			x2 = temp;
		}
		fuzzyTimeline.handles.push({x1:x1,x2:x2});
		fuzzyTimeline.drawHandles();
		//enabled "play" button
		$(fuzzyTimeline.rangeSlider.startAnimation).removeClass("playDisabled").addClass("playEnabled");
	},
	
	selectByX : function(x1,x2){
		var fuzzyTimeline = this;
		if (fuzzyTimeline.viewMode === "density"){
			fuzzyTimeline.density.selectByX(x1,x2);
		} else if (fuzzyTimeline.viewMode === "barchart"){
			fuzzyTimeline.rangeBars.selectByX(x1,x2);
		}		
	},
	
	drawHandles : function(){
		var fuzzyTimeline = this;

		$(fuzzyTimeline.gui.plotDiv).find(".plotHandle").remove();
		$(fuzzyTimeline.gui.plotDiv).find(".dragTimeRangeAlt").remove();
		$(fuzzyTimeline.gui.plotDiv).find(".plotHandleBox").remove();
		
		var plotHeight = (fuzzyTimeline.density.plot?fuzzyTimeline.density.plot:fuzzyTimeline.rangeBars.plot).height();
		var plotWidth = (fuzzyTimeline.density.plot?fuzzyTimeline.density.plot:fuzzyTimeline.rangeBars.plot).width();
		//flot sends the wrong width if we extend the parent div, so scale it accordingly
		plotWidth = plotWidth*fuzzyTimeline.zoomFactor;
		var plotOffset = (fuzzyTimeline.density.plot?fuzzyTimeline.density.plot:fuzzyTimeline.rangeBars.plot).getPlotOffset().left;
		
		$(fuzzyTimeline.handles).each(function(){
			var handle = this;
			
			var moveLeftHandle = function(){
				leftHandle.style.left = handle.x1-$(leftHandle).width() + "px";
			};
			
			var moveRightHandle = function(){
				rightHandle.style.left = handle.x2+ "px";
			};
			
			var resizeHandleBox = function(){
				handleBox.style.left = handle.x1+"px";
				$(handleBox).width(handle.x2-handle.x1);
			};
			
			var moveDragButton = function(){
				dragButton.style.left = (handle.x1+handle.x2)/2 - $(dragButton).width()/2 + "px";
			};
			
			var leftHandle = document.createElement("div");
			leftHandle.title = GeoTemConfig.getString('leftHandle');
			leftHandle.style.backgroundImage = "url(" + GeoTemConfig.path + "leftHandle.png" + ")";
			leftHandle.setAttribute('class', 'plotHandle plotHandleIcon');
			leftHandle.style.visibility = "visible";
			$(fuzzyTimeline.gui.plotDiv).append(leftHandle);
			moveLeftHandle();
			leftHandle.style.top = plotHeight/2-$(leftHandle).height()/2 + "px";
			
			var rightHandle = document.createElement("div");
			rightHandle.title = GeoTemConfig.getString('leftHandle');
			rightHandle.style.backgroundImage = "url(" + GeoTemConfig.path + "rightHandle.png" + ")";
			rightHandle.setAttribute('class', 'plotHandle plotHandleIcon');
			rightHandle.style.visibility = "visible";
			moveRightHandle();
			$(fuzzyTimeline.gui.plotDiv).append(rightHandle);
			
			rightHandle.style.top = plotHeight/2-$(rightHandle).height()/2 + "px";
			
			var handleBox = document.createElement("div");
			$(fuzzyTimeline.gui.plotDiv).append(handleBox);
			$(handleBox).addClass("plotHandleBox");
			resizeHandleBox();
			$(handleBox).height(plotHeight);

			var dragButton = document.createElement("div");
			dragButton.title = GeoTemConfig.getString('dragTimeRange');
			dragButton.style.backgroundImage = "url(" + GeoTemConfig.path + "drag.png" + ")";
			dragButton.setAttribute('class', 'dragTimeRangeAlt plotHandleIcon');
			$(fuzzyTimeline.gui.plotDiv).append(dragButton);
			moveDragButton();
			dragButton.style.top = plotHeight + "px";

			$(leftHandle).mousedown(function(){
				$(fuzzyTimeline.gui.plotDiv).mousemove(function(eventObj){
					var x = eventObj.clientX;
					x += $(fuzzyTimeline.gui.plotDiv).parent().scrollLeft();
					if ((x < handle.x2) &&
						(x >= plotOffset)){
						x = x - leftHandle.offsetWidth;
						handle.x1 = x + $(leftHandle).width();
						
						moveLeftHandle();
						resizeHandleBox();
						moveDragButton();
					}
				});
				$(fuzzyTimeline.gui.plotDiv).mouseup(function(eventObj){
					fuzzyTimeline.selectByX(handle.x1,handle.x2);
					$(fuzzyTimeline.gui.plotDiv).unbind("mouseup");
					$(fuzzyTimeline.gui.plotDiv).unbind("mousemove");
				});
			});

			$(rightHandle).mousedown(function(){
				$(fuzzyTimeline.gui.plotDiv).mousemove(function(eventObj){
					var x = eventObj.clientX;
					x += $(fuzzyTimeline.gui.plotDiv).parent().scrollLeft();
					x = x - rightHandle.offsetWidth;
					if ((x > handle.x1) &&
						(x <= plotOffset+plotWidth)){
						handle.x2 = x;

						moveRightHandle();
						resizeHandleBox();
						moveDragButton();
					}
				});
				$(fuzzyTimeline.gui.plotDiv).mouseup(function(eventObj){
					fuzzyTimeline.selectByX(handle.x1,handle.x2);
					$(fuzzyTimeline.gui.plotDiv).unbind("mouseup");
					$(fuzzyTimeline.gui.plotDiv).unbind("mousemove");
				});
			});
			
			$(dragButton).mousedown(function(){
				$(fuzzyTimeline.gui.plotDiv).mousemove(function(eventObj){
					var x = eventObj.clientX;
					//TODO: for some reason we don't need the scoll offset here
					//this should be investigated?
					//x += $(fuzzyTimeline.gui.plotDiv).parent().scrollLeft();
					var xdiff = x - $(dragButton).offset().left - $(dragButton).width()/2;
					handle.x1 = handle.x1+xdiff;
					handle.x2 = handle.x2+xdiff;
					
					moveLeftHandle();
					moveRightHandle();
					resizeHandleBox();
					moveDragButton();
				});
				$(fuzzyTimeline.gui.plotDiv).mouseup(function(eventObj){
					if (handle.x1 < plotOffset)
						handle.x1 = plotOffset;
					if (handle.x2 > plotOffset+plotWidth)
						handle.x2 = plotOffset+plotWidth;
					
					moveLeftHandle();
					moveRightHandle();
					resizeHandleBox();
					moveDragButton();
					
					fuzzyTimeline.selectByX(handle.x1,handle.x2);
					$(fuzzyTimeline.gui.plotDiv).unbind("mouseup");
					$(fuzzyTimeline.gui.plotDiv).unbind("mousemove");
				});
			});
		});
	},
	
	clearHandles : function(){
		var fuzzyTimeline = this;
		$(fuzzyTimeline.gui.plotDiv).find(".plotHandle").remove();
		$(fuzzyTimeline.gui.plotDiv).find(".dragTimeRangeAlt").remove();
		$(fuzzyTimeline.gui.plotDiv).find(".plotHandleBox").remove();
		fuzzyTimeline.handles = [];
		//disable buttons
		$(fuzzyTimeline.rangeSlider.startAnimation).removeClass("playEnabled").addClass("playDisabled");
		$(fuzzyTimeline.rangeSlider.pauseAnimation).removeClass("pauseEnabled").addClass("pauseDisabled");
		//stop the animation (if one was running)
		fuzzyTimeline.pauseAnimation();
	},
	
	startAnimation : function(){
		var fuzzyTimeline = this;
		fuzzyTimeline.loopFunction = function(steps){
			$(fuzzyTimeline.handles).each(function(){
				if (typeof steps === "undefined")
					steps = 1;
				
				var handle = this;
				var x1 = handle.x1;
				var x2 = handle.x2;
				
				if (typeof handle.width === "undefined")
					handle.width = x2-x1;
				
				var plotWidth = (fuzzyTimeline.density.plot?fuzzyTimeline.density.plot:fuzzyTimeline.rangeBars.plot).width();
				var plotOffset = (fuzzyTimeline.density.plot?fuzzyTimeline.density.plot:fuzzyTimeline.rangeBars.plot).getPlotOffset().left;
				
				var plotMax = plotWidth+plotOffset;
				
				//TODO: has to be plotMin
				if (!((x1 === plotOffset)&&(x2-x1 <= handle.width))){
					x1 += steps;
				}
				if (x2 <= plotMax){
					x2 += steps;
					if (x2 > plotMax)
						x2 = plotMax;
					if (x2-x1 > handle.width){
						x1 = x2-handle.width;
					}
				}
				if (x1 >= plotMax){
					//TODO: has to be plotMin
					x1 = plotOffset;
					x2 = plotOffset;
				}
				
				handle.x1 = x1;
				handle.x2 = x2;
				
				fuzzyTimeline.drawHandles();
				fuzzyTimeline.selectByX(handle.x1, handle.x2);
			});
		};
		
		fuzzyTimeline.loopId = setInterval(function(){
			fuzzyTimeline.loopFunction(10);
		}, 100);
	},

	pauseAnimation : function(){
		var fuzzyTimeline = this;
		clearInterval(fuzzyTimeline.loopId);
		$(fuzzyTimeline.handles).each(function(){
			var handle = this;
			delete handle.width;
		});
	},
	
	//This function enlargens the plot area
	zoomPlot : function(zoomFactor){
		var fuzzyTimeline = this;
		var oldZoomFactor = fuzzyTimeline.zoomFactor; 
		fuzzyTimeline.zoomFactor = zoomFactor;
		if (zoomFactor > 1){
			$(fuzzyTimeline.gui.plotDiv).width(zoomFactor*100+"%");
		} else{
			$(fuzzyTimeline.gui.plotDiv).width("100%");
		}
		//leave place for the scrollbar
		$(fuzzyTimeline.gui.plotDiv).height(fuzzyTimeline.gui.plotDIVHeight-20);
		
		//fit handles
		//this does not make much sense, as the selections are _completely_ different
		//for each scale rate, as the objects may reside in different "ticks" of the graph
		$(fuzzyTimeline.handles).each(function(){
			var handle = this;
			handle.x1 = handle.x1 * (zoomFactor/oldZoomFactor);
			handle.x2 = handle.x2 * (zoomFactor/oldZoomFactor);
		});
	}
};
