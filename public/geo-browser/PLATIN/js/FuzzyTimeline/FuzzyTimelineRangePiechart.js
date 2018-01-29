/*
* FuzzyTimelineRangePiechart.js
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
 * @class FuzzyTimelineRangePiechart
 * Implementation for a fuzzy time-ranges pie chart
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {HTML object} parent div to append the FuzzyTimeline
 */
function FuzzyTimelineRangePiechart(parent,div) {

	this.fuzzyTimeline = this;
	
	this.parent = parent;
	this.options = parent.options;
	
	this.div = div;
	
	this.selected = [];
	
	this.maxSlices = 10;
}

FuzzyTimelineRangePiechart.prototype = {

	initialize : function(datasets) {
		var piechart = this;
		if (piechart.parent.showRangePiechart){
			piechart.datasets = datasets;
			piechart.drawPieChart(piechart.datasets);
		}
	},
	
	drawPieChart : function(datasets){
		var piechart = this;
		//build hashmap of spans (span length -> objects[])
		var spans = [];
		var index = 0;
		$(datasets).each(function(){
			var objects = this;
			//check whether we got "real" dataset or just a set of DataObjects
			if (typeof objects.objects !== "undefined")
				objects = objects.objects;
			$(objects).each(function(){
				var dataObject = this;
				var span;
				if (dataObject.isTemporal){
					span = SimileAjax.DateTime.MILLISECOND;
				} else if (dataObject.isFuzzyTemporal){
					span = dataObject.TimeSpanGranularity;
				}
				
				if (typeof span === "undefined")
					return;

				var found = false;
				$(spans).each(function(){
					if (this.span === span){
						this.objects[index].push(dataObject);
						found = true;
						return false;
					}
				});
				if (found === false){
					var newObjectSet = [];
					for (var i = 0; i < piechart.datasets.length; i++)
						newObjectSet.push([]);
					newObjectSet[index].push(dataObject);
					spans.push({span:span,objects:newObjectSet});
				}
			});
			index++;
		});
		
		//TODO: join elements of span array to keep below certain threshold
		
		//sort array by span length		
		spans.sort(function(a,b){
			return(a.span-b.span);
		});
		
		//create chart data
		var chartData = [];
		$(spans).each(function(){
			var spanElem = this;
			$(spanElem.objects).each(function(){
				var label = "unknown";
				
				if (spanElem.span === SimileAjax.DateTime.MILLENNIUM){
					label = "millenia";
				} else if (spanElem.span === SimileAjax.DateTime.DECADE){
					label = "decades";
				} else if (spanElem.span === SimileAjax.DateTime.CENTURY){
					label = "centuries";
				} else if (spanElem.span === SimileAjax.DateTime.YEAR){
					label = "years";
				} else if (spanElem.span === SimileAjax.DateTime.MONTH){
					label = "months";
				} else if (spanElem.span === SimileAjax.DateTime.DAY){
					label = "days";
				} else if (spanElem.span === SimileAjax.DateTime.HOUR){
					label = "hours";
				} else if (spanElem.span === SimileAjax.DateTime.MINUTE){
					label = "minutes";
				} else if (spanElem.span === SimileAjax.DateTime.SECOND){
					label = "seconds";
				} else if (spanElem.span === SimileAjax.DateTime.MILLISECOND){
					label = "milliseconds";
				}				
	
				chartData.push({label:label,data:this.length});
			});
		});
		
	    $(piechart.div).unbind("plotclick");
		$(piechart.div).unbind("plothover");
		$(piechart.div).empty();
		if (spans.length === 0){
			//TODO: language specific message
			$(piechart.div).append("empty selection");
		} else {
			$.plot($(piechart.div), chartData,
					{
						series: {
							// Make this a pie chart.
							pie: {
								show:true
							}
						},
						legend: { show:false},
						grid: {
				            hoverable: true,
				            clickable: true
				        },
				        tooltip: true,
					}
			);
				
			var lastHighlighted;
			var hoverFunction = function (event, pos, item) {
		        if (item) {
		        	var highlightedSpan =  Math.ceil(item.seriesIndex/piechart.datasets.length);
		        	if (lastHighlighted !== highlightedSpan){
			        	var highlightedObjects = [];
			        	for(;highlightedSpan>=0;highlightedSpan--){
			        		highlightedObjects = GeoTemConfig.mergeObjects(highlightedObjects,spans[highlightedSpan].objects);
			        	}
			        	lastHighlighted = highlightedSpan;
			        }
		        	piechart.triggerHighlight(highlightedObjects);
		        } else {
		        	piechart.triggerHighlight([]);
		        }
		    };
		    $(piechart.div).bind("plothover", hoverFunction);
		    
		    $(piechart.div).bind("plotclick", function (event, pos, item) {
		    	$(piechart.div).unbind("plothover");
		    	if (item){
		    		var selectedSpan =  Math.ceil(item.seriesIndex/piechart.datasets.length);
		        	var selectedObjects = [];
		        	for(;selectedSpan>=0;selectedSpan--){
		        		selectedObjects = GeoTemConfig.mergeObjects(selectedObjects,spans[selectedSpan].objects);
		        	}
		        	piechart.triggerSelection(selectedObjects);
		    	} else {
		        	//if it was a click outside of the pie-chart, enable highlight events
		        	$(piechart.div).bind("plothover", hoverFunction);
		        	//return to old state
		        	piechart.triggerSelection(piechart.selected);
		        	//and redraw piechart
		    		piechart.highlightChanged([]);
		        }
		    });
		}
	},
		
	highlightChanged : function(objects) {
		var piechart = this;
		if (piechart.parent.showRangePiechart){
			//check if this is an empty highlight
			var emptyHighlight = true;
			$(objects).each(function(){
				if ((this instanceof Array) && (this.length > 0)){
					emptyHighlight = false;
					return false;
				}
			});
			
			if (emptyHighlight === false)
				piechart.drawPieChart(GeoTemConfig.mergeObjects(piechart.selected, objects));
			else{
				//return to selection (or all objects, if no selection is active)
				if (piechart.selected.length > 0)
					piechart.drawPieChart(piechart.selected);
				else
					piechart.drawPieChart(piechart.datasets);
			}
		}
	},

	selectionChanged : function(selection) {
		var piechart = this;
		if (piechart.parent.showRangePiechart){
			if( !GeoTemConfig.selectionEvents ){
				return;
			}
			piechart.selected = selection;
			piechart.highlightChanged([]);
		}
	},
	
	triggerHighlight : function(highlightedObjects) {
		this.parent.triggerHighlight(highlightedObjects);
	},

	triggerSelection : function(selectedObjects) {
		this.parent.triggerSelection(selectedObjects);
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
