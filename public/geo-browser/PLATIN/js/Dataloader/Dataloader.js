/*
* Dataloader.js
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
 * @class Dataloader
 * Implementation for a Dataloader UI
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {HTML object} parent div to append the Dataloader
 */
function Dataloader(parent) {

	this.dataLoader = this;
	
	this.parent = parent;
	this.options = parent.options;

	this.initialize();
}

Dataloader.prototype = {

	show : function() {
		this.dataloaderDiv.style.display = "block";
	},

	hide : function() {
		this.dataloaderDiv.style.display = "none";
	},

	initialize : function() {

		this.addStaticLoader();
		this.addLocalStorageLoader();
		this.addKMLLoader();
		this.addKMZLoader();
		this.addCSVLoader();
		this.addLocalKMLLoader();
		this.addLocalCSVLoader();
		this.addLocalXLSXLoader();
		
		// trigger change event on the select so 
		// that only the first loader div will be shown
		$(this.parent.gui.loaderTypeSelect).change();
	},
	
	getFileName : function(url) {
		var fileName = $.url(url).attr('file');
		if ( (typeof fileName === "undefined") || (fileName.length === 0) ){
			fileName = $.url(url).attr('path');
			//startsWith and endsWith defined in SIMILE Ajax (string.js) 
			while (fileName.endsWith("/")){
				fileName = fileName.substr(0,fileName.length-1);
			}
			if (fileName.length > 1)
				fileName = fileName.substr(fileName.lastIndexOf("/")+1);
			else
				fileName = "unnamed dataset";
		}
		return fileName;
	},
	
	distributeDataset : function(dataSet) {
		GeoTemConfig.addDataset(dataSet);
	},
	
	distributeDatasets : function(datasets) {
		GeoTemConfig.addDatasets(datasets);
	},
	
	addStaticLoader : function() {
		if (this.options.staticKML.length > 0){
			$(this.parent.gui.loaderTypeSelect).append("<option value='StaticLoader'>Static Data</option>");
			
			this.StaticLoaderTab = document.createElement("div");
			$(this.StaticLoaderTab).attr("id","StaticLoader");
			
			this.staticKMLList = document.createElement("select");
			$(this.StaticLoaderTab).append(this.staticKMLList);
			
			var staticKMLList = this.staticKMLList;
			var isFirstHeader = true;
			$(this.options.staticKML).each(function(){
				var label = this.label;
				var url = this.url;
				var header = this.header;
				if (typeof header !== "undefined"){
					if (!isFirstHeader)
						$(staticKMLList).append("</optgroup>");
					$(staticKMLList).append("<optgroup label='"+header+"'>");
					isFirstHeader = false;
				} else
					$(staticKMLList).append("<option value='"+url+"'>     "+label+"</option>");
			});
			//close last optgroup (if there were any)
			if (!isFirstHeader)
				$(staticKMLList).append("</optgroup>");
			
			this.loadStaticKMLButton = document.createElement("button");
			$(this.loadStaticKMLButton).text("load");
			$(this.loadStaticKMLButton).addClass(GeoTemConfig.buttonCssClass);
    			$(this.StaticLoaderTab).append(this.loadStaticKMLButton);

			$(this.loadStaticKMLButton).click($.proxy(function(){
				var kmlURL = $(this.staticKMLList).find(":selected").attr("value");
				if (kmlURL.length === 0)
					return;
				var origURL = kmlURL;
				var fileName = this.getFileName(kmlURL);
				if (typeof GeoTemConfig.proxy != 'undefined')
					kmlURL = GeoTemConfig.proxy + kmlURL;
				var kml = GeoTemConfig.getKml(kmlURL);
				if ((typeof kml !== "undefined") && (kml != null)) {
					var dataSet = new Dataset(GeoTemConfig.loadKml(kml), fileName, origURL);
					
					if (dataSet != null)
						this.distributeDataset(dataSet);
				} else
					alert("Could not load file.");
			},this));

			$(this.parent.gui.loaders).append(this.StaticLoaderTab);
		}
	},
	
	addKMLLoader : function() {
		$(this.parent.gui.loaderTypeSelect).append("<option value='KMLLoader'>KML File URL</option>");
		
		this.KMLLoaderTab = document.createElement("div");
		$(this.KMLLoaderTab).attr("id","KMLLoader");
		
		this.kmlURL = document.createElement("input");
		$(this.kmlURL).attr("type","text");
		$(this.KMLLoaderTab).append(this.kmlURL);
		
		this.loadKMLButton = document.createElement("button");
		$(this.loadKMLButton).text("load KML");
		$(this.KMLLoaderTab).append(this.loadKMLButton);

		$(this.loadKMLButton).click($.proxy(function(){
			var kmlURL = $(this.kmlURL).val();
			if (kmlURL.length === 0)
				return;
			var origURL = kmlURL;
			var fileName = this.getFileName(kmlURL);
			if (typeof GeoTemConfig.proxy != 'undefined')
				kmlURL = GeoTemConfig.proxy + kmlURL;
			var kml = GeoTemConfig.getKml(kmlURL);
			if ((typeof kml !== "undefined") && (kml != null)) {
				var dataSet = new Dataset(GeoTemConfig.loadKml(kml), fileName, origURL);
				
				if (dataSet != null)
					this.distributeDataset(dataSet);
			} else
				alert("Could not load file. Please check your URL. If the URL is correct, our " +
					"proxy may prevent the file from loading. In that case please send us an email, " +
					"and we gladly add your host to the white list.");
		},this));

		$(this.parent.gui.loaders).append(this.KMLLoaderTab);
	},
	
	addKMZLoader : function() {
		$(this.parent.gui.loaderTypeSelect).append("<option value='KMZLoader'>KMZ File URL</option>");
		
		this.KMZLoaderTab = document.createElement("div");
		$(this.KMZLoaderTab).attr("id","KMZLoader");
		
		this.kmzURL = document.createElement("input");
		$(this.kmzURL).attr("type","text");
		$(this.KMZLoaderTab).append(this.kmzURL);
		
		this.loadKMZButton = document.createElement("button");
		$(this.loadKMZButton).text("load KMZ");
		$(this.KMZLoaderTab).append(this.loadKMZButton);

		$(this.loadKMZButton).click($.proxy(function(){
	    	
	    	var dataLoader = this;
			
			var kmzURL = $(this.kmzURL).val();
			if (kmzURL.length === 0)
				return;
			var origURL = kmzURL;
			var fileName = dataLoader.getFileName(kmzURL);
			if (typeof GeoTemConfig.proxy != 'undefined')
				kmzURL = GeoTemConfig.proxy + kmzURL;
			
			GeoTemConfig.getKmz(kmzURL, function(kmlArray){
		    	$(kmlArray).each(function(){
					var dataSet = new Dataset(GeoTemConfig.loadKml(this), fileName, origURL);
						
					if (dataSet != null)
						dataLoader.distributeDataset(dataSet);
		    	});
			});
		},this));

		$(this.parent.gui.loaders).append(this.KMZLoaderTab);
	},
	
	addCSVLoader : function() {
		$(this.parent.gui.loaderTypeSelect).append("<option value='CSVLoader'>CSV File URL</option>");
		
		this.CSVLoaderTab = document.createElement("div");
		$(this.CSVLoaderTab).attr("id","CSVLoader");
		
		this.csvURL = document.createElement("input");
		$(this.csvURL).attr("type","text");
		$(this.CSVLoaderTab).append(this.csvURL);
		
		this.loadCSVButton = document.createElement("button");
		$(this.loadCSVButton).text("load CSV");
		$(this.CSVLoaderTab).append(this.loadCSVButton);

		$(this.loadCSVButton).click($.proxy(function(){
			var dataLoader = this;
			
			var csvURL = $(this.csvURL).val();
			if (csvURL.length === 0)
				return;
			var origURL = csvURL;
			var fileName = dataLoader.getFileName(csvURL);
			if (typeof GeoTemConfig.proxy != 'undefined')
				csvURL = GeoTemConfig.proxy + csvURL;
			GeoTemConfig.getCsv(csvURL, function(json){
				if ((typeof json !== "undefined") && (json.length > 0)) {
					var dataSet = new Dataset(GeoTemConfig.loadJson(json), fileName, origURL);
					
					if (dataSet != null)
						dataLoader.distributeDataset(dataSet);
				} else
					alert("Could not load file. Please check your URL. If the URL is correct, our " +
						"proxy may prevent the file from loading. In that case please send us an email, " +
						"and we gladly add your host to the white list.");
			});
		},this));

		$(this.parent.gui.loaders).append(this.CSVLoaderTab);
	},	
	
	addLocalKMLLoader : function() {
		$(this.parent.gui.loaderTypeSelect).append("<option value='LocalKMLLoader'>local KML File</option>");
		
		this.localKMLLoaderTab = document.createElement("div");
		$(this.localKMLLoaderTab).attr("id","LocalKMLLoader");
		
		this.kmlFile = document.createElement("input");
		$(this.kmlFile).attr("type","file");
		$(this.localKMLLoaderTab).append(this.kmlFile);
		
		this.loadLocalKMLButton = document.createElement("button");
		$(this.loadLocalKMLButton).text("load KML");
		$(this.localKMLLoaderTab).append(this.loadLocalKMLButton);

		$(this.loadLocalKMLButton).click($.proxy(function(){
			var filelist = $(this.kmlFile).get(0).files;
			if (filelist.length > 0){
				var file = filelist[0];
				var fileName = file.name;
				var reader = new FileReader();
				
				reader.onloadend = ($.proxy(function(theFile) {
			        return function(e) {
						var dataSet = new Dataset(GeoTemConfig.loadKml($.parseXML(reader.result)), fileName);
						if (dataSet != null)
							this.distributeDataset(dataSet);
			        };
			    }(file),this));

				reader.readAsText(file);
			}
		},this));

		$(this.parent.gui.loaders).append(this.localKMLLoaderTab);
	},
	
	addLocalCSVLoader : function() {
		$(this.parent.gui.loaderTypeSelect).append("<option value='LocalCSVLoader'>local CSV File</option>");
		
		this.localCSVLoaderTab = document.createElement("div");
		$(this.localCSVLoaderTab).attr("id","LocalCSVLoader");
		
		this.csvFile = document.createElement("input");
		$(this.csvFile).attr("type","file");
		$(this.localCSVLoaderTab).append(this.csvFile);
		
		this.loadLocalCSVButton = document.createElement("button");
		$(this.loadLocalCSVButton).text("load CSV");
		$(this.localCSVLoaderTab).append(this.loadLocalCSVButton);

		$(this.loadLocalCSVButton).click($.proxy(function(){
			var filelist = $(this.csvFile).get(0).files;
			if (filelist.length > 0){
				var file = filelist[0];
				var fileName = file.name;
				var reader = new FileReader();
				
				reader.onloadend = ($.proxy(function(theFile) {
			        return function(e) {
			        	var json = GeoTemConfig.convertCsv(reader.result);
						var dataSet = new Dataset(GeoTemConfig.loadJson(json), fileName);
						if (dataSet != null)
							this.distributeDataset(dataSet);			
			        };
			    }(file),this));

				reader.readAsText(file);
			}
		},this));

		$(this.parent.gui.loaders).append(this.localCSVLoaderTab);
	},
	
	addLocalStorageLoader : function() {
		var dataLoader = this;
		this.localStorageLoaderTab = document.createElement("div");
		$(this.localStorageLoaderTab).attr("id","LocalStorageLoader");
		
		var localDatasets = document.createElement("select");
		$(this.localStorageLoaderTab).append(localDatasets);

		var localStorageDatasetCount = 0;
		for(var key in localStorage){
			//TODO: this is a somewhat bad idea, as it is used in multiple widgets.
			//A global GeoTemCo option "prefix" could be better. But still..
			if (key.startsWith("GeoBrowser_dataset_")){
				localStorageDatasetCount++;
				var label = key.substring("GeoBrowser_dataset_".length);
				var url = key;
				$(localDatasets).append("<option value='"+url+"'>"+decodeURIComponent(label)+"</option>");
			}
		}
		
		//only show if there are datasets
		if (localStorageDatasetCount > 0)
			$(this.parent.gui.loaderTypeSelect).append("<option value='LocalStorageLoader'>browser storage</option>");

		this.loadLocalStorageButton = document.createElement("button");
		$(this.loadLocalStorageButton).text("load");
		$(this.localStorageLoaderTab).append(this.loadLocalStorageButton);

		$(this.loadLocalStorageButton).click($.proxy(function(){
			var fileKey = $(localDatasets).find(":selected").attr("value");
			if (fileKey.length === 0)
				return;
			var csv = $.remember({name:fileKey});
			//TODO: this is a somewhat bad idea, as it is used in multiple widgets.
			//A global GeoTemCo option "prefix" could be better. But still..
			var fileName = decodeURIComponent(fileKey.substring("GeoBrowser_dataset_".length));
			var json = GeoTemConfig.convertCsv(csv);
			var dataSet = new Dataset(GeoTemConfig.loadJson(json), fileName, fileKey, "local");
			if (dataSet != null)
				dataLoader.distributeDataset(dataSet);
		},this));

		$(this.parent.gui.loaders).append(this.localStorageLoaderTab);
	},
	
	addLocalXLSXLoader : function() {
		//taken from http://oss.sheetjs.com/js-xlsx/
		var fixdata = function(data) {
			var o = "", l = 0, w = 10240;
			for(; l<data.byteLength/w; ++l) o+=String.fromCharCode.apply(null,new Uint8Array(data.slice(l*w,l*w+w)));
			o+=String.fromCharCode.apply(null, new Uint8Array(data.slice(o.length)));
			return o;
		}
		
		$(this.parent.gui.loaderTypeSelect).append("<option value='LocalXLSXLoader'>local XLS/XLSX File</option>");
		
		this.LocalXLSXLoader = document.createElement("div");
		$(this.LocalXLSXLoader).attr("id","LocalXLSXLoader");
		
		this.xlsxFile = document.createElement("input");
		$(this.xlsxFile).attr("type","file");
		$(this.LocalXLSXLoader).append(this.xlsxFile);
		
		this.loadLocalXLSXButton = document.createElement("button");
		$(this.loadLocalXLSXButton).text("load XLS/XLSX");
		$(this.LocalXLSXLoader).append(this.loadLocalXLSXButton);

		$(this.loadLocalXLSXButton).click($.proxy(function(){
			var filelist = $(this.xlsxFile).get(0).files;
			if (filelist.length > 0){
				var file = filelist[0];
				var fileName = file.name;
				var reader = new FileReader();
				
				reader.onloadend = ($.proxy(function(theFile) {
			        return function(e) {
			        	var workbook;
			        	var json;
			        	if (fileName.toLowerCase().indexOf("xlsx")!=-1){
			        		workbook = XLSX.read(btoa(fixdata(reader.result)), {type: 'base64'});
			        		var csv = XLSX.utils.sheet_to_csv(workbook.Sheets[workbook.SheetNames[0]]);
			        		var json = GeoTemConfig.convertCsv(csv);
			        	} else {
			        		workbook = XLS.read(btoa(fixdata(reader.result)), {type: 'base64'});
			        		var csv = XLS.utils.sheet_to_csv(workbook.Sheets[workbook.SheetNames[0]]);
			        		var json = GeoTemConfig.convertCsv(csv);
			        	}
			        	
						var dataSet = new Dataset(GeoTemConfig.loadJson(json), fileName);
						if (dataSet != null)
							this.distributeDataset(dataSet);			
			        };
			    }(file),this));

				reader.readAsArrayBuffer(file);
			}
		},this));

		$(this.parent.gui.loaders).append(this.LocalXLSXLoader);
	},
};
