/*
* PieChart.js
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
 * @class PieChart
 * Implementation for a PieChart
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {HTML object} parent div to append the PieChart
 */
function PieChart(parent, watchedDataset, watchedColumn, selectionFunction) {

	if ((typeof selectionFunction !== "undefined") &&
		(typeof selectionFunction.type !== "undefined") && 
		(typeof selectionFunction.categories !== "undefined")){
		this.type = selectionFunction.type;
		this.categories = selectionFunction.categories;
	}
	this.pieChart = this;
	this.pieChartDiv;
	this.preHighlightObjects;
	this.highlightedLabel;
	
	this.informationDIV;
	this.pieChartLabel;
	
	this.parent = parent;
	this.options = parent.options;
	
	this.watchedDatasetObject;
	this.watchedDataset = parseInt(watchedDataset);
	this.watchColumn = watchedColumn;
	if (typeof selectionFunction !== "undefined")
		this.selectionFunction = selectionFunction;
	else
		//default selectionFunction returns value (creates "distinct" piechart)
		this.selectionFunction = function(columnData){return columnData;};	
}

PieChart.prototype = {

	remove : function() {
		for (var i = 0; i < this.parent.pieCharts.length; i++){
			if (this.parent.pieCharts[i] === this)
				this.parent.pieCharts[i] = null;
		}			
		$(this.pieChartDiv).remove();
		$(this.informationDIV).remove();
		this.parent.redrawPieCharts();
	},
	
	refreshLabel : function(){
		$(this.pieChartLabel).empty();
		$(this.pieChartLabel).append(this.watchedDatasetObject.label + " - " + this.watchColumn);		
		
		var c = GeoTemConfig.getColor(this.watchedDataset);
		$(this.pieChartLabel).css("color","rgb("+c.r1+","+c.g1+","+c.b1+")");
	},
	
	initialize : function() {
		var pieChart = this;
		
		if (typeof this.pieChartDiv === "undefined"){
			this.informationDIV = document.createElement("div");
			this.pieChartLabel = $("<span></span>");
			$(this.informationDIV).append(this.pieChartLabel);
			this.refreshLabel(); 

			var removeButton = document.createElement("button");
			$(this.informationDIV).append(removeButton);
			$(removeButton).text("remove");
			$(removeButton).click(function(){
				pieChart.remove();
			});

			//only allow editing if it is a "manually" created piechart
			//automatic (with a selection function) ones, can lead to numerous problems,
			//e.g. too many categories or numeral categories threated as text ones
			if ((typeof pieChart.type !== "undefined")&&
				(typeof pieChart.categories !== "undefined")){
				var editButton = document.createElement("button");
				$(this.informationDIV).append(editButton);
				$(editButton).text("edit");
				$(editButton).click(function(){
					var chooser = new PieChartCategoryChooser(
							pieChart.parent,
							pieChart.parent.options,
							pieChart.watchedDataset,
							pieChart.watchColumn,
							pieChart.type,
							pieChart.categories);
				});
				
				//add save button
				if (pieChart.options.allowLocalStorage){
					var saveButton = document.createElement("button");
					$(this.informationDIV).append(saveButton);
					$(saveButton).text("save");
					$(saveButton).click(function(){
						$(	"<div>" +
								"pie chart name : " +
								"<input type='text' size=30 id='saveName' class='ui-widget-content ui-corner-all'></input>" +
							"</div>").dialog({
						        width:'auto',
								buttons: [
								          {
								        	  text: "save",
								        	  click: function(){
								        		  var saveName = $("#saveName").val();
								        		  var saveObject = new Object();
								        		  saveObject.type = pieChart.type;
								        		  saveObject.categories = pieChart.categories;
								        		  saveObject.columnName = pieChart.watchColumn;
								        		  //save to LocalStorage
								        		  $.remember({
								        			  name:pieChart.options.localStoragePrefix+saveName,
								        			  value:saveObject,
								        			  json:true
								        		  });
								        		  $(this).dialog( "close" );
								        	  }
								          }
								]
						});
						
						//set value to default (column name)
						$("#saveName").val(pieChart.watchColumn);
						//TODO: z-index has to be set, as the "tool-bars" of map (.ddbToolbar in style.css)
						//also have a z-index of 10000. z-index should be removed from all elements. 
						$(".ui-dialog").css("z-index",10005);
					});
				}
			}							

			$(this.parent.gui.pieChartsDiv).append(this.informationDIV);
			this.pieChartDiv = document.createElement("div");
			$(this.parent.gui.pieChartsDiv).append(this.pieChartDiv);

			$(this.pieChartDiv).unbind();
		    $(this.pieChartDiv).bind("plothover", function (event, pos, item) {
		    	var highlightedLabel;
		    	
		        if (item) {
		        	highlightedLabel = item.series.label;
		        }
		        if (highlightedLabel !== pieChart.highlightedLabel){
		        	pieChart.highlightedLabel = highlightedLabel;
		        	pieChart.triggerHighlight(highlightedLabel);
		        }
		    });
			
		    $(this.pieChartDiv).bind("plotclick", function (event, pos, item) {
		        if (item) {
					//item.series.label contains the column element
					pieChart.triggerSelection(item.series.label);                              
		        } else {
		        	pieChart.triggerSelection();
		        }
		    });
		}
	},

	//check if dataset is still there
	checkForDataSet : function() {
		var datasets = this.parent.datasets;
		if ((typeof datasets !== "undefined") && (typeof this.watchedDatasetObject !== "undefined")){
			//check if our data went missing
			for (var i = 0; i < datasets.length; i++){
				if (datasets[i] === this.watchedDatasetObject){
					//if dataset "before" this one was removed, the index changes
					if (this.watchedDataset !== i){
						//change color to the new one (changes with index!)
						this.watchedDataset = i;
						this.refreshLabel();
					}					
					return true;
				}
			}
		}
		return false;
	},
	
	initPieChart : function(dataSets) {
		// get dataset object (could not be there on startup, e.g. piechart defined before load completes)
		if (typeof this.watchedDatasetObject === "undefined")
			this.watchedDatasetObject = this.parent.datasets[this.watchedDataset];

		this.initialize();

		// if our dataset went missing, remove this piechart
		if (!this.checkForDataSet()){
				this.remove();
				return;
		}
		
		var objects = [];
		for (var i = 0; i < dataSets.length; i++)
			objects.push([]);
		objects[this.watchedDataset] = dataSets[this.watchedDataset].objects;
		
		this.preHighlightObjects = objects;
		this.redrawPieChart(objects);
	},

	redrawPieChart : function(objects) {
		
		if (typeof objects === "undefined")
			objects = this.preHighlightObjects;
		
		if (this.checkForDataSet(objects)){
			var pieChart = this;
			if (objects[this.watchedDataset].length === 0)
				objects = this.preHighlightObjects;
			
			var calculateSlices = function(dataObjects){
				var chartDataCounter = new Object;

				$(dataObjects).each(function(){
					var columnData = pieChart.parent.getElementData(this, pieChart.watchColumn, pieChart.selectionFunction);
					
					//disregard empty cells
					if ( (typeof columnData === "undefined") || (columnData == "") )
						return;
					
					var weight = this.weight;
				
					if (typeof chartDataCounter[columnData] === "undefined")
						chartDataCounter[columnData] = weight;
					else
						chartDataCounter[columnData] += weight;
				});
				
				var chartData = [];
				$.each(chartDataCounter, function(name,val){
					//get rgb-color (24bit = 6 hex digits) from hash
					var color = '#'+hex_md5(name).substr(0,6);
					chartData.push({label:name,data:val,color:color});
				});
				
				//sort by count (occurances of category)
				var sortByVal = function(a,b){
					return (b.data-a.data);
				};
				chartData.sort(sortByVal);
				
				return chartData;
			};
			
			var chartData = calculateSlices(objects[this.watchedDataset]);
			
			if (chartData.length>0){
				$(this.pieChartDiv).empty();
				
				//calculate height (flot NEEDS a height)				
				var parentHeight = $(this.parent.gui.pieChartsDiv).outerHeight(true) - $(this.parent.gui.columnSelectorDiv).outerHeight(true);
				var pieChartCount = 0;
				$(this.parent.pieCharts).each(function(){
					if (this instanceof PieChart)
						pieChartCount++;
				});
				var height = (parentHeight/pieChartCount) - $(this.informationDIV).outerHeight(true);
				if (pieChart.options.restrictPieChartSize !== false)
					height = Math.min(height, $(window).height() * pieChart.options.restrictPieChartSize);
				$(this.pieChartDiv).height(height);
	
				$.plot($(this.pieChartDiv), chartData,
					{
						series: {
							// Make this a pie chart.
							pie: {
								show:true
							}
						},
						legend: { show:true, position: 'se' },
						grid: {
				            hoverable: true,
				            clickable: true
				        },
				        tooltip: true,
				        tooltipOpts: {
				            content: "%s %p.1%"
				        }
					}
				);
			}
		}
	},
		
	triggerHighlight : function(columnElement) {
		var highlightedObjects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++)
			highlightedObjects.push([]);
		
		if (this.watchedDataset >= 0)
			highlightedObjects[this.watchedDataset] = 
				this.parent.getElementsByValue(columnElement, this.watchedDataset, this.watchColumn, this.selectionFunction);
		else
			highlightedObjects[this.watchedDataset] = [];
		
		this.parent.core.triggerHighlight(highlightedObjects);
		
		var pieChart = this;
		$(this.parent.pieCharts).each(function(){
			if (this instanceof PieChart && (this !== pieChart)){
				if (this.watchedDataset === pieChart.watchedDataset)
					this.redrawPieChart(highlightedObjects);
			}				
		});
	},

	triggerSelection : function(columnElement) {
		var selectedObjects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++)
			selectedObjects.push([]);

		var selection;
		if (typeof columnElement !== "undefined"){
			selectedObjects[this.watchedDataset] = 
				this.parent.getElementsByValue(columnElement, this.watchedDataset, this.watchColumn, this.selectionFunction);
			selection = new Selection(selectedObjects, this);
		} else {
			selection = new Selection(selectedObjects);
		}

		this.parent.core.triggerSelection(selection);
		
		if (!selection.valid()){
			selection.loadAllObjects();
			//"undo" selection (click next to piechart)
			//so also redraw this dataset
			this.preHighlightObjects = selection.objects;
			this.redrawPieChart(selection.objects);
		}			
		
		var pieChart = this;
		$(this.parent.pieCharts).each(function(){
			if (this instanceof PieChart && (this !== pieChart)){
				if (this.watchedDataset === pieChart.watchedDataset){
					this.preHighlightObjects = selection.objects;
					this.redrawPieChart(selection.objects);
				}
			}				
		});
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
