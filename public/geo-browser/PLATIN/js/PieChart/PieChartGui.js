/*
* PieChartGui.js
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
 * @class PieChartGui
 * PieChart GUI Implementation
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {PieChartWidget} parent PieChart widget object
 * @param {HTML object} div parent div to append the PieChart gui
 * @param {JSON} options PieChart configuration
 */
function PieChartGui(pieChart, div, options) {

	this.parent = pieChart;
	this.options = options;
	var pieChartGui = this;
	
	this.pieChartContainer = div;
	this.pieChartContainer.style.position = 'relative';

	this.columnSelectorDiv = document.createElement("div");
	div.appendChild(this.columnSelectorDiv);
	this.datasetSelect = document.createElement("select");
	$(this.datasetSelect).change(function(event){
		if (typeof pieChartGui.parent.datasets !== "undefined"){
			var dataset = pieChartGui.parent.datasets[$(pieChartGui.datasetSelect).val()];
			if (dataset.objects.length > 0){
				//This implies that the dataObjects are homogenous
				var firstObject = dataset.objects[0];
				var firstTableContent = firstObject.tableContent;
				$(pieChartGui.columnSelect).empty();
				
				$(pieChartGui.columnSelect).append("<optgroup label='saved'>");
				
				for(var key in localStorage){
					//TODO: this is a somewhat bad idea, as it is used in multiple widgets.
					//A global GeoTemCo option "prefix" could be better. But still..
					var prefix = pieChartGui.options.localStoragePrefix;
					if (key.startsWith(prefix)){
						var saveObject = $.remember({name:key,json:true});
						var label = key.substring(prefix.length);
						//small safety-check: if the column is not part of this dataset, don't show it
						if (typeof firstTableContent[saveObject.columnName] !== "undefined")
							$(pieChartGui.columnSelect).append("<option isSaved=1 value='"+label+"'>"+decodeURIComponent(label)+"</option>");
					}
				}
				$(pieChartGui.columnSelect).append("</optgroup>");
				
				$(pieChartGui.columnSelect).append("<optgroup label='new'>");
			    for (var attribute in firstTableContent) {
			    	$(pieChartGui.columnSelect).append("<option value='"+attribute+"'>"+attribute+"</option>");
			    }
			    if (firstObject.isTemporal)
			    	$(pieChartGui.columnSelect).append("<option value='dates[0].date'>date</option>");
			    if (typeof firstObject.locations[0] !== "undefined"){
			    	$(pieChartGui.columnSelect).append("<option value='locations[0].latitude'>lat</option>");
			    	$(pieChartGui.columnSelect).append("<option value='locations[0].longitude'>lon</option>");
			    }
				$(pieChartGui.columnSelect).append("</optgroup>");
			}
		}
	});
	this.columnSelectorDiv.appendChild(this.datasetSelect);
	this.columnSelect = document.createElement("select");
	this.columnSelectorDiv.appendChild(this.columnSelect);
	this.buttonNewPieChart = document.createElement("button");
	$(this.buttonNewPieChart).text("add");
	this.columnSelectorDiv.appendChild(this.buttonNewPieChart);
	$(this.buttonNewPieChart).click(function(){
		//check if this is a local saved pie chart
		var isSaved=$(pieChartGui.columnSelect).find("option:selected").first().attr("isSaved");
		if ((typeof isSaved === "undefined") || (isSaved!=1)){
			//create new pie chart (where each value is its own category)
			pieChartGui.parent.addPieChart($(pieChartGui.datasetSelect).val(), $(pieChartGui.columnSelect).val());
		} else {
			//is local saved, get value
			var name = pieChartGui.options.localStoragePrefix + $(pieChartGui.columnSelect).val();
			var saveObject = $.remember({name:name,json:true});
			if ((typeof saveObject !== "undefined") && (saveObject != null)){
				var categories = saveObject.categories;
				var type = saveObject.type;
				var columnName = saveObject.columnName;
				
				//create pie chart
				pieChartGui.parent.addCategorizedPieChart(
						$(pieChartGui.datasetSelect).val(), columnName,
						type, categories);				
			}
		}
	});
	this.buttonPieChartCategoryChooser = document.createElement("button");
	$(this.buttonPieChartCategoryChooser).text("categorize");
	this.columnSelectorDiv.appendChild(this.buttonPieChartCategoryChooser);
	$(this.buttonPieChartCategoryChooser).click(function(){
		//check if this is a local saved pie chart
		var isSaved=$(pieChartGui.columnSelect).find("option:selected").first().attr("isSaved");
		if ((typeof isSaved === "undefined") || (isSaved!=1)){
			var chooser = new PieChartCategoryChooser(	pieChartGui.parent,
					pieChartGui.options,
					$(pieChartGui.datasetSelect).val(),
					$(pieChartGui.columnSelect).val() );
		} else {
			alert("Saved datasets can not be categorized again. Try loading and editing instead.");
		}
	});
	
	this.refreshColumnSelector();
	
	this.pieChartsDiv = document.createElement("div");
	this.pieChartsDiv.id = "pieChartsDivID";
	div.appendChild(this.pieChartsDiv);
	$(this.pieChartsDiv).height("100%");
};

PieChartGui.prototype = {
		
	refreshColumnSelector : function(){
		$(this.datasetSelect).empty();
		$(this.columnSelect).empty();
		
		if ( (typeof this.parent.datasets !== "undefined") && (this.parent.datasets.length > 0)) {
			var index = 0;
			var pieChartGui = this;
			$(this.parent.datasets).each(function(){
				$(pieChartGui.datasetSelect).append("<option value="+index+">"+this.label+"</option>");
				index++;
			});
			
			$(pieChartGui.datasetSelect).change();
		}
	}
};