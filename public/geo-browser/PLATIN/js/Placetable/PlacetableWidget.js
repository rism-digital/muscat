/*
* PlacetableWidget.js
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
 * @class PlacetableWidget
 * PlacetableWidget Implementation
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {WidgetWrapper} core wrapper for interaction to other widgets
 * @param {HTML object} div parent div to append the Placetable widget div
 * @param {JSON} options user specified configuration that overwrites options in PlacetableConfig.js
 */
PlacetableWidget = function(core, div, options) {

	this.datasets;
	this.core = core;
	this.core.setWidget(this);

	this.options = (new PlacetableConfig(options)).options;
	this.gui = new PlacetableGui(this, div, this.options);
}

PlacetableWidget.prototype = {

	initWidget : function(data) {
		this.datasets = data;
		var placetableWidget = this;
		
		$(placetableWidget.gui.placetablesTable).empty();

		this.elementHash = [];
		var datasetIndex = 0;
		$(this.datasets).each(function(){
			var dataset = this;
			
			placetableWidget.elementHash[datasetIndex] = [];
			
			var row = document.createElement("tr");
			var rowHeader = document.createElement("td");
			
			rowHeader.innerHTML = "<b>"+this.label+"</b>";
			$(rowHeader).mouseover($.proxy(function(){
				placetableWidget.mouseover(dataset);
			},{dataset:dataset,placetableWidget:placetableWidget}));
			$(rowHeader).mouseout($.proxy(function(){
				placetableWidget.mouseout(dataset);
			},{dataset:dataset,placetableWidget:placetableWidget}));
			$(rowHeader).click($.proxy(function(){
				placetableWidget.click(dataset);
			},{dataset:dataset,placetableWidget:placetableWidget}));
			
			$(row).append(rowHeader);
			
			$(this.objects).each(function(){
				var object = this;
				var rowElement = document.createElement("td");
								
				rowElement.innerHTML = this.getPlace(0,0);
				$(rowElement).mouseover($.proxy(function(){
					placetableWidget.mouseover(dataset,object);
				},{dataset:dataset,object:object,placetableWidget:placetableWidget}));
				$(rowElement).mouseout($.proxy(function(){
					placetableWidget.mouseout(dataset,object);
				},{dataset:dataset,object:object,placetableWidget:placetableWidget}));
				$(rowElement).click($.proxy(function(){
					placetableWidget.click(dataset,object);
				},{dataset:dataset,object:object,placetableWidget:placetableWidget}));

				$(row).append(rowElement);
				
				placetableWidget.elementHash[datasetIndex][object.index] = rowElement;
			});
			
			$(placetableWidget.gui.placetablesTable).append(row);
			
			datasetIndex++;
		});
		
		this.highlightChanged([]);
	},
	
	mouseover : function(dataset,object) {
		var highlightedObjects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++){
			if (GeoTemConfig.datasets[i] === dataset){
				//if label is selected, push all objects of this set
				if (typeof object === "undefined"){
					var highlightedInDataset = [];
					$(dataset.objects).each(function(){
						highlightedInDataset.push(this);
					});
					highlightedObjects.push(highlightedInDataset);
				} else {
					//otherwise only push this object
					highlightedObjects.push([object]);
				}				
			} else {
				highlightedObjects.push([]);
			}
		}
		
		this.core.triggerHighlight(highlightedObjects);		
	},
	
	mouseout : function(dataset,object) {
		//select none
		var highlightedObjects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++)
			highlightedObjects.push([]);
		
		this.core.triggerHighlight(highlightedObjects);		
	},
	
	click : function(dataset,object) {
	},
	
	highlightChanged : function(objects) {
		if( !GeoTemConfig.highlightEvents ){
			return;
		}
		var placetableWidget = this;
		
		//reset colors
		var datasetIndex = 0;
		$(placetableWidget.elementHash).each(function(){
			var color = GeoTemConfig.getColor(datasetIndex);
			var colorRGB = 'rgb(' + color.r0 + ',' + color.g0 + ',' + color.b0 + ')';
			
			$(this).each(function(){
				$(this).css('background-color', colorRGB);
			});
			datasetIndex++;
		});	
		
		//paint the selected
		var datasetIndex = 0;
		$(objects).each(function(){
			var color = GeoTemConfig.getColor(datasetIndex);
			var colorRGB = 'rgb(' + color.r1 + ',' + color.g1 + ',' + color.b1 + ')';
			$(this).each(function(){
				var object = this;
				
				var rowElement = placetableWidget.elementHash[datasetIndex][object.index];

				$(rowElement).css('background-color', colorRGB);
			});
			datasetIndex++;
		});
	},

	selectionChanged : function(selection) {
		if( !GeoTemConfig.selectionEvents ){
			return;
		}
	},
};
