/*
* TableWidget.js
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
 * @class TableWidget
 * TableWidget Implementation
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {TableWrapper} core wrapper for interaction to other widgets
 * @param {HTML object} div parent div to append the table widget div
 * @param {JSON} options user specified configuration that overwrites options in TableConfig.js
 */
TableWidget = function(core, div, options) {

	this.core = core;
	this.core.setWidget(this);
	this.tables = [];
	this.tableTabs = [];
	this.tableElements = [];
	this.tableHash = [];

	this.options = (new TableConfig(options)).options;
	this.gui = new TableGui(this, div, this.options);
	this.filterBar = new FilterBar(this);

}

TableWidget.prototype = {

	initWidget : function(data) {
		this.datasets = data;

		$(this.gui.tabs).empty();
		$(this.gui.input).empty();
		this.activeTable = undefined;
		this.tables = [];
		this.tableTabs = [];
		this.tableElements = [];
		this.tableHash = [];
		this.selection = new Selection();
		this.filterBar.reset(false);

		var tableWidget = this;
		var addTab = function(name, index) {
			var dataSet = GeoTemConfig.datasets[index];
			var tableTab = document.createElement('div');
			var tableTabTable = document.createElement('table');
			$(tableTab).append(tableTabTable);
			var tableTabTableRow = document.createElement('tr');
			$(tableTabTable).append(tableTabTableRow);
			tableTab.setAttribute('class', 'tableTab');
			var c = GeoTemConfig.getColor(index);
			tableTab.style.backgroundColor = 'rgb(' + c.r0 + ',' + c.g0 + ',' + c.b0 + ')';
			tableTab.onclick = function() {
				tableWidget.selectTable(index);
			}
			var tableNameDiv = document.createElement('div');
			$(tableNameDiv).append(name);
			
			if (typeof dataSet.url !== "undefined"){
				var tableLinkDiv = document.createElement('a');
				tableLinkDiv.title = dataSet.url;
				tableLinkDiv.href = dataSet.url;
				tableLinkDiv.target = '_';
				tableLinkDiv.setAttribute('class', 'externalLink');
				$(tableNameDiv).append(tableLinkDiv);
			}
			$(tableTabTableRow).append($(document.createElement('td')).append(tableNameDiv));
			
			var removeTabDiv = document.createElement('div');
			removeTabDiv.setAttribute('class', 'smallButton removeDataset');
			removeTabDiv.title = GeoTemConfig.getString('removeDatasetHelp');
			removeTabDiv.onclick = $.proxy(function(e) {
				GeoTemConfig.removeDataset(index);
				//don't let the event propagate to the DIV above			
				e.stopPropagation();
				//discard link click
				return(false);
			},{index:index});
			$(tableTabTableRow).append($(document.createElement('td')).append(removeTabDiv));
			
			if (GeoTemConfig.tableExportDataset){
				var exportTabDiv = document.createElement('div');
				exportTabDiv.setAttribute('class', 'smallButton exportDataset');
				exportTabDiv.title = GeoTemConfig.getString('exportDatasetHelp');
				var exportTabForm = document.createElement('form');
				//TODO: make this configurable
				exportTabForm.action = 'php/download.php';
				exportTabForm.method = 'post';
				var exportTabHiddenValue = document.createElement('input');
				exportTabHiddenValue.name = 'file';
				exportTabHiddenValue.type = 'hidden';
				exportTabForm.appendChild(exportTabHiddenValue);
				exportTabDiv.onclick = $.proxy(function(e) {
					$(exportTabHiddenValue).val(GeoTemConfig.createKMLfromDataset(index));
					$(exportTabForm).submit();
					//don't let the event propagate to the DIV				
					e.stopPropagation();
					//discard link click
					return(false);
				},{index:index});
				exportTabDiv.appendChild(exportTabForm);
				$(tableTabTableRow).append($(document.createElement('td')).append(exportTabDiv));
			}
			
			if (GeoTemConfig.allowUserShapeAndColorChange){
				var dataset = GeoTemConfig.datasets[index];

				var changeColorShapeSelect = $("<select></select>");
				changeColorShapeSelect.attr("title", GeoTemConfig.getString("colorShapeDatasetHelp"));
				changeColorShapeSelect.css("font-size","1.5em");
				
				var currentOptgroup = $("<optgroup label='Current'></optgroup>");
				var currentOption = $("<option value='current'></option>");
				var color = GeoTemConfig.getColor(index);
				currentOption.css("color","rgb("+color.r1+","+color.g1+","+color.b1+")");
				currentOption.data("color",{r1:color.r1,g1:color.g1,b1:color.b1,r0:color.r0,g0:color.g0,b0:color.b0});
				if (dataset.graphic.shape=="circle"){
					currentOption.append("●");
				} else if (dataset.graphic.shape=="triangel"){
					currentOption.append("▲");
				} else if (dataset.graphic.shape=="square"){
					if (dataset.graphic.rotation===0){
						currentOption.append("■");
					} else {
						currentOption.append("◆");
					}
				}
				currentOptgroup.append(currentOption);
				changeColorShapeSelect.append(currentOptgroup);

				var defaultOptgroup = $("<optgroup label='Default'></optgroup>");
				var defaultOption = $("<option value='default'></option>");
				var color = GeoTemConfig.colors[index];
				defaultOption.css("color","rgb("+color.r1+","+color.g1+","+color.b1+")");
				defaultOption.data("color",{r1:color.r1,g1:color.g1,b1:color.b1,r0:color.r0,g0:color.g0,b0:color.b0});
				defaultOption.append("●");
				defaultOptgroup.append(defaultOption);
				changeColorShapeSelect.append(defaultOptgroup);
				
				var shapeOptgroup = $("<optgroup label='Shapes'></optgroup>");
				shapeOptgroup.append("<option>○</option>");
				shapeOptgroup.append("<option>□</option>");
				shapeOptgroup.append("<option>◇</option>");
				shapeOptgroup.append("<option>△</option>");
				changeColorShapeSelect.append(shapeOptgroup);
				
				var colorOptgroup = $("<optgroup label='Colors'></optgroup>");
				var red = $("<option style='color:red'>■</option>");
				red.data("color",{r1:255,g1:0,b1:0});
				colorOptgroup.append(red);
				var green = $("<option style='color:green'>■</option>");
				green.data("color",{r1:0,g1:255,b1:0});
				colorOptgroup.append(green);
				var blue = $("<option style='color:blue'>■</option>");
				blue.data("color",{r1:0,g1:0,b1:255});
				colorOptgroup.append(blue);
				var yellow = $("<option style='color:yellow'>■</option>");
				yellow.data("color",{r1:255,g1:255,b1:0});
				colorOptgroup.append(yellow);
				changeColorShapeSelect.append(colorOptgroup);
				
				changeColorShapeSelect.change($.proxy(function(e) {
					var selected = changeColorShapeSelect.find("option:selected");

					//credits: Pimp Trizkit @ http://stackoverflow.com/a/13542669
					function shadeRGBColor(color, percent) {
					    var f=color.split(","),t=percent<0?0:255,p=percent<0?percent*-1:percent,R=parseInt(f[0].slice(4)),G=parseInt(f[1]),B=parseInt(f[2]);
					    return "rgb("+(Math.round((t-R)*p)+R)+","+(Math.round((t-G)*p)+G)+","+(Math.round((t-B)*p)+B)+")";
					}

					var color = selected.data("color");
					
					if (typeof color !== "undefined"){
						if (	(typeof color.r0 === "undefined") ||
								(typeof color.g0 === "undefined") ||
								(typeof color.b0 === "undefined") ){
							var shadedrgb = shadeRGBColor("rgb("+color.r1+","+color.g1+","+color.b1+")",0.7);
							shadedrgb = shadedrgb.replace("rgb(","").replace(")","");
							shadedrgb = shadedrgb.split(",");
							
							color.r0 = parseInt(shadedrgb[0]);
							color.g0 = parseInt(shadedrgb[1]);
							color.b0 = parseInt(shadedrgb[2]);
						}
					}

					var shapeText = selected.text();
					var graphic;
					if ((shapeText=="■") || (shapeText=="□")){
						graphic = {
								shape: "square",
								rotation: 0
						};
					} else if ((shapeText=="●") || (shapeText=="○")){
						graphic = {
								shape: "circle",
								rotation: 0
						};
					} else if ((shapeText=="◆") || (shapeText=="◇")){
						graphic = {
								shape: "square",
								rotation: 45
						};
					} else if ((shapeText=="▲") || (shapeText=="△")){
						graphic = {
								shape: "triangle",
								rotation: 0
						};
					}
					
					if (shapeOptgroup.has(selected).length>0){
						//shape change
						dataset.graphic = graphic;
					} else if (colorOptgroup.has(selected).length>0){
						//color changed
						dataset.color = color;
					} else {
						//back to default
						dataset.graphic = graphic;
						dataset.color = color;
					}
					
					//reload data
					Publisher.Publish('filterData', GeoTemConfig.datasets, null);
					
					//don't let the event propagate to the DIV				
					e.stopPropagation();
					//discard link click
					return(false);
				},{index:index}));
				$(tableTabTableRow).append($(document.createElement('td')).append(changeColorShapeSelect));
			}
			
			return tableTab;
		}
		tableWidget.addTab = addTab;
		
		for (var i in data ) {
			this.tableHash.push([]);
			var tableTab = addTab(data[i].label, i);
			this.gui.tabs.appendChild(tableTab);
			this.tableTabs.push(tableTab);
			var elements = [];
			for (var j in data[i].objects ) {
				elements.push(new TableElement(data[i].objects[j]));
				this.tableHash[i][data[i].objects[j].index] = elements[elements.length - 1];
			}
			var table = new Table(elements, this, i);
			this.tables.push(table);
			this.tableElements.push(elements);
		}

		if (data.length > 0) {
			this.selectTable(0);
		}

	},

	getHeight : function() {
		if (this.options.tableHeight) {
			return this.gui.tableContainer.offsetHeight - this.gui.tabs.offsetHeight;
		}
		return false;
	},

	selectTable : function(index) {
		if (this.activeTable != index) {
			if ( typeof this.activeTable != 'undefined') {
				this.tables[this.activeTable].hide();
				var c = GeoTemConfig.getColor(this.activeTable);
				this.tableTabs[this.activeTable].style.backgroundColor = 'rgb(' + c.r0 + ',' + c.g0 + ',' + c.b0 + ')';
			}
			this.activeTable = index;
			this.tables[this.activeTable].show();
			var c = GeoTemConfig.getColor(this.activeTable);
			this.tableTabs[this.activeTable].style.backgroundColor = 'rgb(' + c.r1 + ',' + c.g1 + ',' + c.b1 + ')';
			this.core.triggerRise(index);
		}

	},

	highlightChanged : function(objects) {
		if( !GeoTemConfig.highlightEvents || (typeof this.tables[this.activeTable] === "undefined")){
			return;
		}
		if( this.tables.length > 0 ){
			return;
		}
		for (var i = 0; i < this.tableElements.length; i++) {
			for (var j = 0; j < this.tableElements[i].length; j++) {
				this.tableElements[i][j].highlighted = false;
			}
		}
		for (var i = 0; i < objects.length; i++) {
			for (var j = 0; j < objects[i].length; j++) {
				this.tableHash[i][objects[i][j].index].highlighted = true;
			}
		}
		this.tables[this.activeTable].update();
	},

	selectionChanged : function(selection) {
		if( !GeoTemConfig.selectionEvents || (typeof this.tables[this.activeTable] === "undefined")){
			return;
		}
		this.reset();
		if( this.tables.length == 0 ){
			return;
		}
		this.selection = selection;
		for (var i = 0; i < this.tableElements.length; i++) {
			for (var j = 0; j < this.tableElements[i].length; j++) {
				this.tableElements[i][j].selected = false;
				this.tableElements[i][j].highlighted = false;
			}
		}
		var objects = selection.getObjects(this);
		for (var i = 0; i < objects.length; i++) {
			for (var j = 0; j < objects[i].length; j++) {
				this.tableHash[i][objects[i][j].index].selected = true;
			}
		}
		this.tables[this.activeTable].reset();
		this.tables[this.activeTable].update();
	},

	triggerHighlight : function(item) {
		var selectedObjects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++) {
			selectedObjects.push([]);
		}
		if ( typeof item != 'undefined') {
			selectedObjects[this.activeTable].push(item);
		}
		this.core.triggerHighlight(selectedObjects);
	},

	tableSelection : function() {
		var selectedObjects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++) {
			selectedObjects.push([]);
		}
		var valid = false;
		for (var i = 0; i < this.tableElements.length; i++) {
			for (var j = 0; j < this.tableElements[i].length; j++) {
				var e = this.tableElements[i][j];
				if (e.selected) {
					selectedObjects[i].push(e.object);
					valid = true;
				}
			}
		}
		this.selection = new Selection();
		if (valid) {
			this.selection = new Selection(selectedObjects, this);
		}
		this.core.triggerSelection(this.selection);
		this.filterBar.reset(true);
	},

	deselection : function() {
		this.reset();
		this.selection = new Selection();
		this.core.triggerSelection(this.selection);
	},

	filtering : function() {
		for (var i = 0; i < this.datasets.length; i++) {
			this.datasets[i].objects = this.selection.objects[i];
		}
		this.core.triggerRefining(this.datasets);
	},

	inverseFiltering : function() {
		var selectedObjects = [];
		for (var i = 0; i < GeoTemConfig.datasets.length; i++) {
			selectedObjects.push([]);
		}
		var valid = false;
		for (var i = 0; i < this.tableElements.length; i++) {
			for (var j = 0; j < this.tableElements[i].length; j++) {
				var e = this.tableElements[i][j];
				if (!e.selected) {
					selectedObjects[i].push(e.object);
					valid = true;
				}
			}
		}
		this.selection = new Selection();
		if (valid) {
			this.selection = new Selection(selectedObjects, this);
		}
		this.filtering();
	},

	triggerRefining : function() {
		this.core.triggerRefining(this.selection.objects);
	},

	reset : function() {
		this.filterBar.reset(false);
		if( this.tables.length > 0 ){
			this.tables[this.activeTable].resetElements();
			this.tables[this.activeTable].reset();
			this.tables[this.activeTable].update();
		}
	}
}
