/*
* StorytellingWidget.js
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
 * @class StorytellingWidget
 * StorytellingWidget Implementation
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {WidgetWrapper} core wrapper for interaction to other widgets
 * @param {HTML object} div parent div to append the Storytelling widget div
 * @param {JSON} options user specified configuration that overwrites options in StorytellingConfig.js
 */
StorytellingWidget = function(core, div, options) {

	this.datasets;
	this.core = core;
	this.core.setWidget(this);
	this.currentStatus = new Object();

	this.options = (new StorytellingConfig(options)).options;
	this.gui = new StorytellingGui(this, div, this.options);
	
	this.datasetLink;
	
	Publisher.Subscribe('mapChanged', this, function(mapName) {
		this.client.currentStatus["mapChanged"] = mapName;
		this.client.createLink();
	});
	
	var currentStatus = $.url().param("currentStatus");
	if (typeof currentStatus !== "undefined"){
		this.currentStatus = $.deparam(currentStatus);
		$.each(this.currentStatus,function(action,data){
			Publisher.Publish(action, data, this);
		});
	}
}

StorytellingWidget.prototype = {

	initWidget : function(data) {
		var storytellingWidget = this;
		var gui = storytellingWidget.gui;
		
		storytellingWidget.datasets = data;
		
		$(gui.storytellingContainer).empty();
		
		var magneticLinkParam = "";
		var datasetIndex = 0;
		var linkCount = 1;
		$(storytellingWidget.datasets).each(function(){
			var dataset = this;
			
			if (magneticLinkParam.length > 0)
				magneticLinkParam += "&";

			var paragraph = $("<p></p>");
			paragraph.append(dataset.label);
			if (typeof dataset.url !== "undefined"){
				//TODO: makes only sense for KML or CSV URLs, so "type" of
				//URL should be preserved (in dataset).
				//startsWith and endsWith defined in SIMILE Ajax (string.js) 
				var type="csv";
				if (typeof dataset.type !== "undefined")
					type = dataset.type;
				else {
					if (dataset.url.toLowerCase().endsWith("kml"))
						type = "kml";
				}

				magneticLinkParam += type+linkCount+"=";
				linkCount++;
				magneticLinkParam += dataset.url;
				
				var tableLinkDiv = document.createElement('a');
				tableLinkDiv.title = dataset.url;
				tableLinkDiv.href = dataset.url;
				tableLinkDiv.target = '_';
				tableLinkDiv.setAttribute('class', 'externalLink');
				paragraph.append(tableLinkDiv);
			} else {
				if (storytellingWidget.options.dariahStorage){
					var uploadToDARIAH = document.createElement('a');
					$(uploadToDARIAH).append("Upload to DARIAH Storage");
					uploadToDARIAH.title = "";
					uploadToDARIAH.href = dataset.url;
					
					var localDatasetIndex = new Number(datasetIndex);
					$(uploadToDARIAH).click(function(){
						var csv = GeoTemConfig.createCSVfromDataset(localDatasetIndex);
						// taken from dariah.storage.js
						var storageURL = "http://ref.dariah.eu/storage/"
					    $.ajax({
							url: storageURL,
							type: 'POST',
							contentType: 'text/csv',
							data: csv,
							success: function(data, status, xhr) {
								var location = xhr.getResponseHeader('Location');
								// the dariah storage id
							    dsid = location.substring(location.lastIndexOf('/')+1);
							    
							    //add URL to dataset
							    storytellingWidget.datasets[localDatasetIndex].url = location;
							    storytellingWidget.datasets[localDatasetIndex].type = "csv";
							    //refresh list
							    storytellingWidget.initWidget(storytellingWidget.datasets);
							},
							error: function (data, text, error) {
								alert('error creating new file in dariah storage because ' + text);
								console.log(data);
								console.log(text);
								console.log(error);
							}
					    });					
						//discard link click-event
						return(false);
					});
					paragraph.append(uploadToDARIAH);
				}
				// TODO: if layout is more usable, both options could be used ("else" removed)
				else if (storytellingWidget.options.localStorage){
					var saveToLocalStorage = document.createElement('a');
					$(saveToLocalStorage).append("Save to Local Storage");
					saveToLocalStorage.title = "";
					saveToLocalStorage.href = dataset.url;
					
					var localDatasetIndex = new Number(datasetIndex);
					$(saveToLocalStorage).click(function(){
						var csv = GeoTemConfig.createCSVfromDataset(localDatasetIndex);

						var storageName = "GeoBrowser_dataset_"+GeoTemConfig.datasets[localDatasetIndex].label;
						$.remember({
							name:storageName,
							value:csv
						});

						//add URL to dataset
					    storytellingWidget.datasets[localDatasetIndex].url = storageName;
					    storytellingWidget.datasets[localDatasetIndex].type = "local";
					    //refresh list
					    storytellingWidget.initWidget(storytellingWidget.datasets);
						
						//discard link click-event
						return(false);
					});
					paragraph.append(saveToLocalStorage);
				}
			}
			
			$(gui.storytellingContainer).append(paragraph);
			datasetIndex++;
		});
		
		this.datasetLink = magneticLinkParam;
		this.createLink();
	},
	
	createLink : function() {
		$(this.gui.storytellingContainer).find('.magneticLink').remove();

		var magneticLink = document.createElement('a');
		magneticLink.setAttribute('class', 'magneticLink');
		$(magneticLink).append("Magnetic Link");
		magneticLink.title = "Use this link to reload currently loaded (online) data.";
		magneticLink.href = "?"+this.datasetLink;
		var currentStatusParam = $.param(this.currentStatus);
		if (currentStatusParam.length > 0)
			magneticLink.href += "&currentStatus="+currentStatusParam;
		magneticLink.target = '_';
		$(this.gui.storytellingContainer).prepend(magneticLink);
	},
	
	highlightChanged : function(objects) {
	},

	selectionChanged : function(selection) {
	},
};
