/*
* DataloaderWidget.js
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
 * @class DataloaderWidget
 * DataloaderWidget Implementation
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {WidgetWrapper} core wrapper for interaction to other widgets
 * @param {HTML object} div parent div to append the Dataloader widget div
 * @param {JSON} options user specified configuration that overwrites options in DataloaderConfig.js
 */
DataloaderWidget = function(core, div, options) {

	this.core = core;
	this.core.setWidget(this);

	this.options = (new DataloaderConfig(options)).options;
	this.gui = new DataloaderGui(this, div, this.options);
	
	this.dataLoader = new Dataloader(this);
	
	this.datasets = [];
}

DataloaderWidget.prototype = {

	initWidget : function() {

		var dataloaderWidget = this;
	},

	highlightChanged : function(objects) {
		if( !GeoTemConfig.highlightEvents ){
			return;
		}
	},

	selectionChanged : function(selection) {
		if( !GeoTemConfig.selectionEvents ){
			return;
		}
	},

	triggerHighlight : function(item) {
	},

	tableSelection : function() {
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
	
	loadRenames : function(){
		//load (optional!) attribute renames
		//each rename param is {latitude:..,longitude:..,place:..,date:..,timeSpanBegin:..,timeSpanEnd:..}
		//examples:
		//	&rename1={"latitude":"lat1","longitude":"lon1"}
		//	&rename2=[{"latitude":"lat1","longitude":"lon1"},{"latitude":"lat2","longitude":"lon2"}]
		var dataLoaderWidget = this;
		var datasets = dataLoaderWidget.datasets;
		$.each($.url().param(),function(paramName, paramValue){
			if (paramName.toLowerCase().startsWith("rename")){
				var datasetID = parseInt(paramName.replace(/\D/g,''));
				var dataset;
				if (isNaN(datasetID)){
					var dataset;
					for (datasetID in datasets){
						break;
					}
				}
				dataset = datasets[datasetID];

				if (typeof dataset === "undefined")
					return;
				
				var renameFunc = function(index,latAttr,lonAttr,placeAttr,dateAttr,timespanBeginAttr,
						timespanEndAttr,indexAttr){
					var renameArray = [];
					
					if (typeof index === "undefined"){
						index = 0;
					}
					
					if ((typeof latAttr !== "undefined") && (typeof lonAttr !== "undefined")){
						renameArray.push({
							oldColumn:latAttr,
							newColumn:"locations["+index+"].latitude"
						});
						renameArray.push({
							oldColumn:lonAttr,
							newColumn:"locations["+index+"].longitude"
						});
					}
					
					if (typeof placeAttr !== "undefined"){
						renameArray.push({
							oldColumn:placeAttr,
							newColumn:"locations["+index+"].place"
						});
					}

					if (typeof dateAttr !== "undefined"){
						renameArray.push({
							oldColumn:dateAttr,
							newColumn:"dates["+index+"]"
						});
					}

					if ((typeof timespanBeginAttr !== "undefined") && 
							(typeof timespanEndAttr !== "undefined")){
						renameArray.push({
							oldColumn:timespanBeginAttr,
							newColumn:"tableContent[TimeSpan:begin]"
						});
						renameArray.push({
							oldColumn:timespanEndAttr,
							newColumn:"tableContent[TimeSpan:end]"
						});
					}

					if (typeof indexAttr !== "undefined"){
						renameArray.push({
							oldColumn:indexAttr,
							newColumn:"index"
						});
					}
					
					GeoTemConfig.renameColumns(dataset,renameArray);
				};
				
				var renames = JSON.parse(paramValue);

				if (renames instanceof Array){
					for (var i=0; i < renames.length; i++){
						renameFunc(i,renames[i].latitude,renames[i].longitude,renames[i].place,renames[i].date,
							renames[i].timeSpanBegin,renames[i].timeSpanEnd,renames[i].index);
					}
				} else {
					renameFunc(0,renames.latitude,renames.longitude,renames.place,renames.date,
							renames.timeSpanBegin,renames.timeSpanEnd,renames.index);
				}
			}
		});
	},
	
	loadFilters : function(){
		//load (optional!) filters
		//those will create a new(!) dataset, that only contains the filtered IDs
		var dataLoaderWidget = this;
		var datasets = dataLoaderWidget.datasets;
		$.each($.url().param(),function(paramName, paramValue){
			//startsWith and endsWith defined in SIMILE Ajax (string.js)
			if (paramName.toLowerCase().startsWith("filter")){
				var datasetID = parseInt(paramName.replace(/\D/g,''));
				var dataset;
				if (isNaN(datasetID)){
					var dataset;
					for (datasetID in datasets){
						break;
					}
				}
				dataset = datasets[datasetID];
				
				if (typeof dataset === "undefined")
					return;
				
				var filterValues = function(paramValue){
					var filter = JSON.parse(paramValue);
					var filteredObjects = [];
					for(var i = 0; i < dataset.objects.length; i++){
						var dataObject = dataset.objects[i];
						if ($.inArray(dataObject.index,filter) != -1){
							filteredObjects.push(dataObject);
						}
					}
					var filteredDataset = new Dataset(filteredObjects, dataset.label + " (filtered)", dataset.url, dataset.type);
					datasets.push(filteredDataset);
				}
				
				if (paramValue instanceof Array){
					for (var i=0; i < paramValue.length; i++){
						filterValues(paramValue[i]);
					}
				} else {
					filterValues(paramValue);
				}

			}
		});		
	},
	
	loadColors : function(){
		//Load the (optional!) dataset colors
		var dataLoaderWidget = this;
		var datasets = dataLoaderWidget.datasets;
		$.each($.url().param(),function(paramName, paramValue){
			if (paramName.toLowerCase().startsWith("color")){
				//color is 1-based, index is 0-based!
				var datasetID = parseInt(paramName.replace(/\D/g,''));
				if (datasets.length > datasetID){
					if (typeof datasets[datasetID].color === "undefined"){
						var color = new Object();
						var colorsSelectedUnselected = paramValue.split(",");
						if (colorsSelectedUnselected.length > 2)
							return;
						
						var color1 = colorsSelectedUnselected[0];
						if (color1.length != 6)
							return;
						
						color.r1 = parseInt(color1.substr(0,2),16);
						color.g1 = parseInt(color1.substr(2,2),16);
						color.b1 = parseInt(color1.substr(4,2),16);
						
						//check if a unselected color is given
						if (colorsSelectedUnselected.length == 2){
							var color0 = colorsSelectedUnselected[1];
							if (color0.length != 6)
								return;
							
							color.r0 = parseInt(color0.substr(0,2),16);
							color.g0 = parseInt(color0.substr(2,2),16);
							color.b0 = parseInt(color0.substr(4,2),16);
						} else {
							//if not: use the selected color "halved"
							color.r0 = Math.round(color.r1/2);
							color.g0 = Math.round(color.g1/2);
							color.b0 = Math.round(color.b1/2);
						}
						
						datasets[datasetID].color = color;
					}	
				}
			}	
		});		
	},
	
	loadFromURL : function() {
		var dataLoaderWidget = this;
		dataLoaderWidget.datasets = [];
		//using jQuery-URL-Parser (https://github.com/skruse/jQuery-URL-Parser)
		var datasets = dataLoaderWidget.datasets;
		var parametersHash = $.url().param();
		var parametersArray = [];
		$.each(parametersHash,function(paramName, paramValue){
			parametersArray.push({paramName:paramName, paramValue:paramValue});
		});
		
		var parseParam = function(paramNr){
			
			if (paramNr==parametersArray.length){
				dataLoaderWidget.loadRenames();
				dataLoaderWidget.loadFilters();
				dataLoaderWidget.loadColors();

				//delete undefined entries in the array
				//(can happen if the sequence given in the URL is not complete
				// e.g. kml0=..,kml2=..)
				//this also reorders the array,	 starting with 0
				var tempDatasets = [];
				for(var index in datasets){
					if (datasets[index] instanceof Dataset){
						tempDatasets.push(datasets[index]);
					}
				}
				datasets = tempDatasets;
				
				if (datasets.length > 0){
					dataLoaderWidget.dataLoader.distributeDatasets(datasets);
				}
				return;
			}
			
			var paramName = parametersArray[paramNr].paramName;
			var paramValue = parametersArray[paramNr].paramValue;

			var datasetID = parseInt(paramName.replace(/\D/g,''));
			
			//startsWith and endsWith defined in SIMILE Ajax (string.js)
			var fileName = dataLoaderWidget.dataLoader.getFileName(paramValue);
			var origURL = paramValue;
			if (typeof GeoTemConfig.proxy != 'undefined')
				paramValue = GeoTemConfig.proxy + paramValue;
			if (paramName.toLowerCase().startsWith("kml")){
				GeoTemConfig.getKml(paramValue, function(kmlDoc){
					var dataSet = new Dataset(GeoTemConfig.loadKml(kmlDoc), fileName, origURL);
					if (dataSet != null){
						if (!isNaN(datasetID)){
							datasets[datasetID] = dataSet;
						} else {
							datasets.push(dataSet);							
						}
					}
					setTimeout(function(){parseParam(paramNr+1)},1);
				});
			}
			else if (paramName.toLowerCase().startsWith("csv")){
				console.log("DATASET");
                GeoTemConfig.getCsv(paramValue,function(json){
					var dataSet = new Dataset(GeoTemConfig.loadJson(json), fileName, origURL);
                    
					if (dataSet != null){
                        
						if (!isNaN(datasetID)){
							datasets[datasetID] = dataSet;
						} else {
							datasets.push(dataSet);							
						}
					}
					setTimeout(function(){parseParam(paramNr+1)},1);
				});
			}
			else if (paramName.toLowerCase().startsWith("json")){
				GeoTemConfig.getJson(paramValue,function(json ){
					var dataSet = new Dataset(GeoTemConfig.loadJson(json), fileName, origURL);
					if (dataSet != null){
						if (!isNaN(datasetID)){
							datasets[datasetID] = dataSet;
						} else {
							datasets.push(dataSet);							
						}
					}
					setTimeout(function(){parseParam(paramNr+1)},1);
				});
			}
			else if (paramName.toLowerCase().startsWith("local")){
				var csv = $.remember({name:encodeURIComponent(origURL)});
				//TODO: this is a bad idea and will be changed upon having a better
				//usage model for local stored data
				var fileName = origURL.substring("GeoBrowser_dataset_".length);
				var json = GeoTemConfig.convertCsv(csv);
				var dataSet = new Dataset(GeoTemConfig.loadJson(json), fileName, origURL, "local");
				if (dataSet != null){
					if (!isNaN(datasetID)){
						datasets[datasetID] = dataSet;
					} else {
						datasets.push(dataSet);							
					}
				}
				setTimeout(function(){parseParam(paramNr+1)},1);
			} else if (paramName.toLowerCase().startsWith("xls")){
				GeoTemConfig.getBinary(paramValue,function(binaryData){
					var data = new Uint8Array(binaryData);
					var arr = new Array();
					for(var i = 0; i != data.length; ++i){
						arr[i] = String.fromCharCode(data[i]);
					}
					
					var workbook;
		        	var json;
		        	if (paramName.toLowerCase().startsWith("xlsx")){
		        		workbook = XLSX.read(arr.join(""), {type:"binary"});
		        		var csv = XLSX.utils.sheet_to_csv(workbook.Sheets[workbook.SheetNames[0]]);
		        		var json = GeoTemConfig.convertCsv(csv);
		        	} else {
		        		workbook = XLS.read(arr.join(""), {type:"binary"});
		        		var csv = XLS.utils.sheet_to_csv(workbook.Sheets[workbook.SheetNames[0]]);
		        		var json = GeoTemConfig.convertCsv(csv);
		        	}
		        	
					var dataSet = new Dataset(GeoTemConfig.loadJson(json), fileName, origURL);
					if (dataSet != null){
						if (!isNaN(datasetID)){
							datasets[datasetID] = dataSet;
						} else {
							datasets.push(dataSet);							
						}
					}
					setTimeout(function(){parseParam(paramNr+1)},1);
				});
			} else {
				setTimeout(function(){parseParam(paramNr+1)},1);
			}
		};
		
		if (parametersArray.length>0){
			parseParam(0)
		}
	}
};
