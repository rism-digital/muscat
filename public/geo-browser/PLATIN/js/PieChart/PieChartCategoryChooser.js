/*
* PieChartCategoryChooser.js
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
 * @class PieChartCategoryChooser
 * PieChart dialog for category creation
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {PieChartWidget} parent PieChart widget object
 * @param {JSON} options PieChart configuration
 * @param {number} datasetIndex index of the dataset
 * @param {String} columnName name of the column
 */

function PieChartCategoryChooser(pieChart, options, datasetIndex, columnName, type, categories) {

	var pieChartCategoryChooser = this;
	
	this.parent = pieChart;
	this.options = options;
	this.datasetIndex = parseInt(datasetIndex);
	this.columnName = columnName;
	this.chartData;
		
	this.dialog = $("<div></div>");
	this.dialog.html("").dialog({modal: true}).dialog('open');

	//to asure that the dialog is above (z-index of) the toolbars
	$(".ui-front").css("z-index","10001");
	
	var allNumeric = this.loadValues(datasetIndex, columnName);	

	if (typeof allNumeric === "undefined")
		return;
	if (allNumeric === true){
		this.createNumeralBasedChooser(this.chartData, categories);			
	} else {
		this.createTextBasedChooser(this.chartData, categories);
	}
};

PieChartCategoryChooser.prototype = {

	loadValues : function(datasetIndex, columnName){
		var pieChartCategoryChooser = this;
		
		var allNumeric = true;
		pieChartCategoryChooser.chartData = [];
		var chartData = pieChartCategoryChooser.chartData; 
		$(GeoTemConfig.datasets[datasetIndex].objects).each(function(){
			var columnData = 
				pieChartCategoryChooser.parent.getElementData(this, columnName);
			
			if (isNaN(parseFloat(columnData)))
				allNumeric = false;
			
			if ($.inArray(columnData, chartData) == -1)
				chartData.push(columnData);
		});
		
		if (chartData.length === 0)
			return;
		else
			return allNumeric; 
	},
	
	createTextBasedChooser : function(chartData, categories){
		var pieChartCategoryChooser = this;
		
		var addCategory = function(name,elements){
			var newCategoryContainer = document.createElement("fieldset");
			var newCategoryLegend = document.createElement("legend");
			var newCategoryName = document.createElement("input");
			$(newCategoryName).width("80%");
			newCategoryName.type = "text";
			newCategoryName.value = name;
			var newCategoryRemove = document.createElement("button");
			$(newCategoryRemove).text("X");
			$(newCategoryRemove).click(function(){
				$(newCategoryContainer).find("li").each(function(){
					//move all elements to unselected list
					//("unselected" is defined below)
					//prepend so the items appear on top
					$(this).prependTo(unselected);
				});				
				//and remove this category
				$(newCategoryContainer).remove();
			});
			$(newCategoryLegend).append(newCategoryName);
			$(newCategoryLegend).append(newCategoryRemove);
			$(newCategoryContainer).append(newCategoryLegend);
			$(newCategoryContainer).width("200px");
			$(newCategoryContainer).css("float","left");
			var newCategory = document.createElement("ul");
			$(newCategory).addClass("connectedSortable");
			$(newCategory).css("background", "#eee");
			newCategoryContainer.appendChild(newCategory);
			$(newCategory).append("<br/>");
			cell.appendChild(newCategoryContainer);
			//if there are pre-selected elements (e.g. "edit")
			//add them and remove them from unselected value list
			if (typeof elements !== "undefined"){
				$(elements).each(function(){
					var value = this;
					//add to category
					$(newCategory).append("<li>"+value+"</li>");
					//remove from unselected list 
					$(unselected).find("li").filter(function(){
						return ($(this).text() === ""+value);
					}).remove();
				});
			}

			$( ".connectedSortable" ).sortable({
				connectWith: ".connectedSortable" 
			}).disableSelection();
		};
		
		var table = document.createElement("table");
		var row = document.createElement("tr");
		table.appendChild(row);
		var cell = document.createElement("td");
		row.appendChild(cell);
		cell = document.createElement("td");
		row.appendChild(cell);
		var addCategoryButton = document.createElement("button");
		$(addCategoryButton).text("add new category");
		cell.appendChild(addCategoryButton);
		var applyCategoryButton = document.createElement("button");
		$(applyCategoryButton).text("apply");
		cell.appendChild(applyCategoryButton);
		
		row = document.createElement("tr");
		table.appendChild(row);
		cell = document.createElement("td");
		row.appendChild(cell);
		var unselected = document.createElement("ul");
		$(unselected).addClass("connectedSortable");
		cell.appendChild(unselected);
		cell = document.createElement("td");
		$(cell).attr("valign","top");
		$(cell).width("100%");
		row.appendChild(cell);
		
		this.dialog.append(table);
		
		$( ".connectedSortable" ).sortable({
			connectWith: ".connectedSortable" 
		}).disableSelection();
		
		$(chartData).each(function(){
			$(unselected).append("<li class='ui-state-default'>"+this+"</li>");
		});
		
		if (typeof categories !== "undefined"){
			$(categories).each(function(){
				var category = this;
				addCategory(category.label, category.values);
			});
		}
		
		$(addCategoryButton).click(function(){addCategory();});
		
		$(applyCategoryButton).click(function(){
			var categories = [];
			$(cell).children().each(function(){
				var label = $(this).find("legend > input").val();
				var values = [];
				$(this).find("li").each(function(){
					values.push($(this).text());
				});
				
				categories.push({label:label,values:values});
			});
			
			var values = [];
			$(unselected).find("li").each(function(){
				values.push($(this).text());
			});
			
			categories.push({label:"other",values:values});
			
			//create pie chart
			pieChartCategoryChooser.parent.addCategorizedPieChart(
					pieChartCategoryChooser.datasetIndex, pieChartCategoryChooser.columnName, 
					"text", categories);
		
			//close dialog
			$(pieChartCategoryChooser.dialog).dialog("close");
		});	
		
		//set dialog size
	    var wWidth = $(window).width();
	    var dWidth = wWidth * 0.9;
	    var wHeight = $(window).height();
	    var dHeight = wHeight * 0.9;
	    $(this.dialog).dialog("option", "width", dWidth);
	    $(this.dialog).dialog("option", "height", dHeight);
	},
	
	createNumeralBasedChooser : function(chartData, existingCategories){
		var numericChartData = [];
		for (var i = 0; i < chartData.length; i++){
			numericChartData.push(parseFloat(chartData[i]));
		}
		chartData = numericChartData;
		chartData = chartData.sort(function sortNumber(a,b){
		    return a - b;
		});

		var min = chartData[0];
		var max = chartData[chartData.length-1];
		//find minimum step width that is needed 
		//(otherwise there could be steps that contain more than one element)
		var minStep=max-min;
		for (var i = 1; i < chartData.length; i++){
			var thisStep = chartData[i]-chartData[i-1];
			if ((thisStep) < minStep)
				minStep = thisStep;
		}
		
		var pieChartCategoryChooser = this;
		
		var addCategoryButton = document.createElement("button");
		$(addCategoryButton).text("add new category");
		this.dialog.append(addCategoryButton);
		var applyCategoryButton = document.createElement("button");
		$(applyCategoryButton).text("apply");
		this.dialog.append(applyCategoryButton);
		this.dialog.append("tip: use left/right arrow key for finer adjustment");
		
		var table = document.createElement("table");
		row = document.createElement("tr");
		table.appendChild(row);
		cell = document.createElement("td");
		row.appendChild(cell);
		cell.colSpan = 2;
		var slider = document.createElement("div");
		cell.appendChild(slider);
		var handles = [];
		var categories = [];
		
		row = document.createElement("tr");
		table.appendChild(row);
		cell = document.createElement("td");
		$(cell).attr("valign","top");
		row.appendChild(cell);
		var unselected = document.createElement("ul");
		cell.appendChild(unselected);
		
		cell = document.createElement("td");
		$(cell).attr("valign","top");
		$(cell).width("100%");
		row.appendChild(cell);
		
		this.dialog.append(table);
		
		$(chartData).each(function(){
			$(unselected).append("<li class='ui-state-default'>"+this+"</li>");
		});
		
		var addCategory = function(boundary){
			//check if another handle can be added
			if ((handles.length>0) && (handles[handles.length-1] === max))
				return false;
			//destroy old slider (has to be recreated to show the new handle)
			if (handles.length>0)
				$(slider).slider("destroy");

			if (typeof boundary === "undefined")
				boundary = max;
			handles.push(boundary);
			
			$(slider).slider({
				min:min,
				max:max,
				step:minStep,
				values: handles
			});
			
			var placeValues = function(){
				$(unselected).find("li").remove();
				$(cell).children().find("li").remove();

				var j = 0, i = 0;
				for (; i < chartData.length; i++){
					if (chartData[i]>handles[j])
						j++;
					if (j == handles.length)
						break;
					$(categories[j]).append("<li class='ui-state-default'>"+chartData[i]+"</li>");
				}
				for (; i < chartData.length; i++){
					$(unselected).append("<li class='ui-state-default'>"+chartData[i]+"</li>");
				}
			};
			
			$(slider).on( "slide", function( event, ui ){
				var last = min;
				//check whether handle values are increasing
				for(var i = 0; i < ui.values.length; i++){
					if (ui.values[i]<last)
						return false;
					last = ui.values[i];
				}
				handles = ui.values;
				for(var i = 0; i < handles.length; i++){
					$(categories[i]).parent().find("legend").text("<="+handles[i]);	
				}				
				
				placeValues();
			});

			var newCategoryContainer = document.createElement("fieldset");
			$(newCategoryContainer).append("<legend><="+boundary+"</legend>");
			$(newCategoryContainer).width("188px");
			$(newCategoryContainer).css("float","left");
			var newCategory = document.createElement("ul");
			$(newCategory).addClass("connectedSortable");
			$(newCategory).css("background", "#eee");
			newCategoryContainer.appendChild(newCategory);
			cell.appendChild(newCategoryContainer);
			categories.push(newCategory);
			
			placeValues();
		};
		
		$(addCategoryButton).click(function(){addCategory();});

		if (typeof existingCategories !== "undefined"){
			$(existingCategories).each(function(){
				var boundary = this;
				addCategory(boundary);
			});
		}

		$(applyCategoryButton).click(function(){
			var categorieBoundaries = handles;
			
			//create pie chart
			pieChartCategoryChooser.parent.addCategorizedPieChart(
					pieChartCategoryChooser.datasetIndex, pieChartCategoryChooser.columnName,
					"numeral", categorieBoundaries);
		
			//close dialog
			$(pieChartCategoryChooser.dialog).dialog("close");
		});	
		
		//set dialog size
	    var wWidth = $(window).width();
	    var dWidth = wWidth * 0.9;
	    var wHeight = $(window).height();
	    var dHeight = wHeight * 0.9;
	    $(this.dialog).dialog("option", "width", dWidth);
	    $(this.dialog).dialog("option", "height", dHeight);
	}
};