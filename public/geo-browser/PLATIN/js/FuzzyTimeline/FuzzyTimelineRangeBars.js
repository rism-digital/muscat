/*
* FuzzyTimelineRangeBars.js
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
 * @class FuzzyTimelineRangeBars
 * Implementation for a fuzzy time-ranges barchart
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {HTML object} parent div to append the FuzzyTimeline
 */
function FuzzyTimelineRangeBars(parent) {

	this.rangeBars = this;
	
	this.parent = parent;
	this.options = parent.options;
	
	this.datasets;
	//contains selected data
	this.selected = undefined;
	
	this.datasetsPlot;
	this.highlightedDatasetsPlot;
	this.yValMin;
	this.yValMax;
	this.displayType;
	
	this.plotDiv = this.parent.gui.plotDiv;

	this.spanWidth;
	this.tickSpans;
	this.plot;
}

FuzzyTimelineRangeBars.prototype = {

	initialize : function(datasets) {
		var rangeBar = this;
		
		rangeBar.datasets = datasets;
		rangeBar.selected = [];
	},
	
	createPlot : function(datasets) {
		var rangeBar = this;
		var plots = [];
		var objectHashes = [];
		
		//-1 because last span is always empty (only there to have the ending date)
		var tickCount = rangeBar.tickSpans.length-1;
		
		$(datasets).each(function(){
			var chartDataCounter = [];
			var objectHash = new Object();
			
			for (var i = 0; i < tickCount; i++){
				chartDataCounter[i]=0;
			}
			//check if we got "real" datasets, or just array of objects
			var datasetObjects = this;
			if (typeof this.objects !== "undefined")
				datasetObjects = this.objects;
			$(datasetObjects).each(function(){
				var ticks = rangeBar.parent.getTicks(this, rangeBar.spanWidth);
				if (typeof ticks !== "undefined"){
					var exactTickCount = 
						ticks.firstTickPercentage+
						ticks.lastTickPercentage+
						(ticks.lastTick-ticks.firstTick-1);
					for (var i = ticks.firstTick; i <= ticks.lastTick; i++){
						var weight = 0;
						//calculate the weight for each span, that the object overlaps
						if (rangeBar.parent.options.timelineMode == 'fuzzy'){
							//in fuzzy mode, each span gets just a fraction of the complete weight
							if (i == ticks.firstTick)
								weight = this.weight * ticks.firstTickPercentage/exactTickCount;
							else if (i == ticks.lastTick)
								weight = this.weight * ticks.lastTickPercentage/exactTickCount;
							else
								weight = this.weight * 1/exactTickCount;
						} else if (rangeBar.parent.options.timelineMode == 'stacking'){
							//in stacking mode each span gets the same amount.
							//(besides first and last..)
							if (i == ticks.firstTick)
								weight = this.weight * ticks.firstTickPercentage;
							else if (i == ticks.lastTick)
								weight = this.weight * ticks.lastTickPercentage;
							else
								weight = this.weight;
						}

						chartDataCounter[i] += weight;
						//add this object to the hash
						if (typeof objectHash[i] === "undefined")
							objectHash[i] = [];
						objectHash[i].push(this);
					}
				}
			});
			
			//scale according to selected type
			chartDataCounter = rangeBar.parent.scaleData(chartDataCounter);
			
			//transform data so it can be passed to the flot barchart
			var plotData = [];
			for (var i = 0; i < tickCount; i++){
				plotData[i] = [];
				plotData[i][0] = i;
				plotData[i][1] = chartDataCounter[i];
			}
			
			//delete bars with 0 values
			for (var i = 0; i < tickCount; i++){
				if (plotData[i][1]==0)
					delete plotData[i];
			}
			
			plots.push(plotData);
			objectHashes.push(objectHash);
		});
		
		return {plots:plots, hashs:objectHashes};
	},
	
	showPlot : function(){
		var rangeBar = this;
		var plot = rangeBar.datasetsPlot;
		var highlight_select_plot = $.merge([],plot);
		
		//see if there are selected/highlighted values
		if (rangeBar.highlightedDatasetsPlot instanceof Array){
			//check if plot is some other - external - graph
			if (plot === rangeBar.datasetsPlot)
				highlight_select_plot = $.merge(highlight_select_plot,rangeBar.highlightedDatasetsPlot);
		}
		
		var tickCount = rangeBar.tickSpans.length-1;
		var ticks = [];
		
		var axisFormatString = "YYYY";
		if (rangeBar.spanWidth<60*1000){
			axisFormatString = "YYYY/MM/DD HH:mm:ss";
		} else if (rangeBar.spanWidth<60*60*1000) {
			axisFormatString = "YYYY/MM/DD HH:mm";
		} else if (rangeBar.spanWidth<24*60*60*1000){
			axisFormatString = "YYYY/MM/DD HH";
		} else if (rangeBar.spanWidth<31*24*60*60*1000){
			axisFormatString = "YYYY/MM/DD";
		} else if (rangeBar.spanWidth<12*31*24*60*60*1000){
			axisFormatString = "YYYY/MM";
		}
		//only show ~10 labels on the x-Axis (increase if zoomed)
		var labelModulo = Math.ceil(tickCount/(10*rangeBar.parent.zoomFactor));
		for (var i = 0; i < tickCount; i++){
			var tickLabel = "";
			if (i%labelModulo==0){
				tickLabel = rangeBar.tickSpans[i].format(axisFormatString);
			}
			while ((tickLabel.length > 1) && (tickLabel.indexOf("0")==0))
				tickLabel = tickLabel.substring(1);
			ticks[i] = [i,tickLabel];
		}
		
		var options = {
				series:{
	                bars:{show: true}
	            },
				grid: {
		            hoverable: true,
		            clickable: true,
		            backgroundColor: rangeBar.parent.options.backgroundColor,
		            borderWidth: 0,
		            minBorderMargin: 0,
		        },
		        xaxis: {          
		        	ticks: ticks,
		        	min : 0, 
					max : tickCount,
		        },
		        yaxis: {
		        	min : rangeBar.yValMin,
		        	max : rangeBar.yValMax*1.05
		        },
		        tooltip: true,
		        tooltipOpts: {
		            content: function(label, xval, yval, flotItem){
		    			var fromLabel = rangeBar.tickSpans[xval].format(axisFormatString);
		    			while ((fromLabel.length > 1) && (fromLabel.indexOf("0")==0))
		    				fromLabel = fromLabel.substring(1);
		    			var toLabel = rangeBar.tickSpans[xval+1].clone().subtract("ms",1).format(axisFormatString);
		    			while ((toLabel.length > 1) && (toLabel.indexOf("0")==0))
		    				toLabel = toLabel.substring(1);
		            	highlightString =	fromLabel + " - " + toLabel + " : ";
		            	//(max.)2 Nachkomma-Stellen von y-Wert anzeigen
		            	highlightString +=	Math.round(yval*100)/100; 

		        		return highlightString;
		            }
		        },
		        selection: { 
		        	mode: "x"
		        }
			};
		if (!rangeBar.parent.options.showYAxis)
			options.yaxis.show=false;
		
		var highlight_select_plot_colors = [];		
		var i = 0;
		$(highlight_select_plot).each(function(){
			var color;
			if (i < GeoTemConfig.datasets.length){
				var datasetColors = GeoTemConfig.getColor(i);
				if (highlight_select_plot.length>GeoTemConfig.datasets.length)
					color = "rgb("+datasetColors.r0+","+datasetColors.g0+","+datasetColors.b0+")";
				else 
					color = "rgb("+datasetColors.r1+","+datasetColors.g1+","+datasetColors.b1+")";
			} else {
				var datasetColors = GeoTemConfig.getColor(i-GeoTemConfig.datasets.length);
				color = "rgb("+datasetColors.r1+","+datasetColors.g1+","+datasetColors.b1+")";
			}			
			
			highlight_select_plot_colors.push({
				color : color,
				data : this
			});
			i++;
		});		
		
		$(rangeBar.plotDiv).unbind();		
		rangeBar.plot = $.plot($(rangeBar.plotDiv), highlight_select_plot_colors, options);
		rangeBar.parent.drawHandles();
		
		var density = rangeBar.parent.density;
		if (typeof density !== "undefined")
			$(rangeBar.plotDiv).unbind("plothover", density.hoverFunction);
		$(rangeBar.plotDiv).unbind("plothover", rangeBar.hoverFunction);
	    $(rangeBar.plotDiv).bind("plothover", $.proxy(rangeBar.hoverFunction,rangeBar));

	    //this var prevents the execution of the plotclick event after a select event 
	    rangeBar.wasSelection = false;
		$(rangeBar.plotDiv).unbind("plotclick");
	    $(rangeBar.plotDiv).bind("plotclick", $.proxy(rangeBar.clickFunction,rangeBar));
	    
	    $(rangeBar.plotDiv).unbind("plotselected");
	    $(rangeBar.plotDiv).bind("plotselected", $.proxy(rangeBar.selectFunction,rangeBar));	
	},
	
	hoverFunction : function (event, pos, item) {
		var rangeBar = this;
    	var hoverBar;
    	var spans;
        if (item) {
        	hoverBar = item.datapoint[0];
        }
        //remember last date, so that we don't redraw the current state
        //that date may be undefined is on purpose
    	if (rangeBar.highlighted !== hoverBar){
    		rangeBar.highlighted = hoverBar;
    		if (typeof hoverBar === "undefined")
    			rangeBar.triggerHighlight();
    		else
    			rangeBar.triggerHighlight(hoverBar);
        }
    },
	
    clickFunction : function (event, pos, item) {
    	var rangeBar = this;
    	if (rangeBar.wasSelection)
    		rangeBar.wasSelection = false;
    	else {
        	//remove selection handles (if there were any)
        	rangeBar.parent.clearHandles();
        	
	    	var clickBar;
	        if (item) {
				//contains the x-value (date)
	        	clickBar = item.datapoint[0];
	        }  	
    		if (typeof clickBar === "undefined")
    			rangeBar.triggerSelection();
    		else
    			rangeBar.triggerSelection(clickBar);
        	wasDataClick = true;
        }
    },
    
    selectFunction : function(event, ranges) {
    	var rangeBar = this;
    	startBar = Math.floor(ranges.xaxis.from);
    	endBar = Math.floor(ranges.xaxis.to);
    	rangeBar.triggerSelection(startBar, endBar);
    	rangeBar.wasSelection = true;
    	
    	rangeBar.parent.clearHandles();
    	var xaxis = rangeBar.plot.getAxes().xaxis;
    	var x1 = rangeBar.plot.pointOffset({x:ranges.xaxis.from,y:0}).left;
    	var x2 = rangeBar.plot.pointOffset({x:ranges.xaxis.to,y:0}).left;
    	rangeBar.parent.addHandle(x1,x2);
    },
    
	selectByX : function(x1, x2){
		rangeBar = this;
		var xaxis = rangeBar.plot.getAxes().xaxis;
		var offset = rangeBar.plot.getPlotOffset().left;
    	var from = Math.floor(xaxis.c2p(x1-offset));
    	var to = Math.floor(xaxis.c2p(x2-offset));
    	
		rangeBar.triggerSelection(from, to);
	},	
	
	drawRangeBarChart : function(datasets, spanWidth){
		var rangeBar = this;
		rangeBar.spanWidth = spanWidth; 
		rangeBar.tickSpans = rangeBar.parent.getSpanArray(rangeBar.spanWidth);
		//-1 because last span is always empty (only there to have the ending date)
		var tickCount = rangeBar.tickSpans.length-1;
		
		if (tickCount > rangeBar.options.maxBars){
			var zoomFactor = tickCount / rangeBar.options.maxBars;
			rangeBar.parent.zoomPlot(zoomFactor);
		} else
			rangeBar.parent.zoomPlot(1);
		
		rangeBar.yValMin = 0;
		rangeBar.yValMax = 0;
		
		var plotAndHash = rangeBar.createPlot(datasets);
		rangeBar.datasetsPlot = plotAndHash.plots;
		rangeBar.datasetsHash = plotAndHash.hashs;
		delete rangeBar.highlightedDatasetsPlot;
		//redraw selected plot to fit (possible) new scale
		rangeBar.selectionChanged(rangeBar.selected);
		
		//get min and max values
		for (var i = 0; i < rangeBar.datasetsPlot.length; i++){
			for (var j = 0; j < rangeBar.datasetsPlot[i].length; j++){
				if (typeof rangeBar.datasetsPlot[i][j] !== "undefined"){
					var val = rangeBar.datasetsPlot[i][j][1];
					
					if (val < rangeBar.yValMin)
						rangeBar.yValMin = val;
					if (val > rangeBar.yValMax)
						rangeBar.yValMax = val;
				}
			}
		}
		
		rangeBar.showPlot();
	},
	
	highlightChanged : function(objects) {
		if( !GeoTemConfig.highlightEvents ){
			return;
		}
		var rangeBar = this;
		var emptyHighlight = true;
		var selected_highlighted = objects;
		if (typeof rangeBar.selected !== "undefined")
			var selected_highlighted = GeoTemConfig.mergeObjects(objects,rangeBar.selected);
		$(selected_highlighted).each(function(){
			if ((this instanceof Array) && (this.length > 0)){
				emptyHighlight = false;
				return false;
			}
		});
		if (emptyHighlight && (typeof rangeBar.selected === "undefined")){
			rangeBar.highlightedDatasetsPlot = [];
		} else {
			rangeBar.highlightedDatasetsPlot = rangeBar.createPlot(selected_highlighted).plots;
		}			
		rangeBar.showPlot();
	},
	
	selectionChanged : function(objects) {
		if( !GeoTemConfig.selectionEvents ){
			return;
		}
		var rangeBar = this;
		rangeBar.selected = objects;
		rangeBar.highlightChanged([]);
	},
	
	triggerHighlight : function(hoverPoint) {
		var rangeBar = this;
		var highlightedObjects = [];
		
		if (typeof hoverPoint !== "undefined"){
			$(rangeBar.datasetsHash).each(function(){
				if (typeof this[hoverPoint] !== "undefined")
					highlightedObjects.push(this[hoverPoint]);
				else
					highlightedObjects.push([]);
			});
		} else {
			for (var i = 0; i < GeoTemConfig.datasets.length; i++)
				highlightedObjects.push([]);
		}
		
		this.parent.core.triggerHighlight(highlightedObjects);
	},

	triggerSelection : function(startBar, endBar) {
		var rangeBar = this;
		var selection;
		if (typeof startBar !== "undefined") {
			if (typeof endBar === "undefined")
				endBar = startBar;
			rangeBar.selected = [];
			$(rangeBar.datasetsHash).each(function(){
				var objects = [];
				for (var i = startBar; i <= endBar; i++){
					$(this[i]).each(function(){
						if ($.inArray(this, objects) == -1){
							objects.push(this);
						}
					});
				}				
				rangeBar.selected.push(objects);
			});
			selection = new Selection(rangeBar.selected, rangeBar.parent);
		} else {
			rangeBar.selected = [];
			for (var i = 0; i < GeoTemConfig.datasets.length; i++)
				rangeBar.selected.push([]);
			selection = new Selection(rangeBar.selected);
		}
		
		rangeBar.parent.selectionChanged(selection);
		rangeBar.parent.core.triggerSelection(selection);
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
