/*
* GeoTemConfig.js
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
 * @class GeoTemConfig
 * Global GeoTemCo Configuration File
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */


// credits: user76888, The Digital Gabeg (http://stackoverflow.com/questions/1539367)
$.fn.cleanWhitespace = function() {
	textNodes = this.contents().filter(	function() { 
		return (this.nodeType == 3 && !/\S/.test(this.nodeValue)); 
	}).remove();
	return this;
};

GeoTemConfig = {
	debug : false, //show debug output (esp. regarding corrupt datasets)
	incompleteData : true, // show/hide data with either temporal or spatial metadata
	inverseFilter : true, // if inverse filtering is offered
	mouseWheelZoom : true, // enable/disable zoom with mouse wheel on map & timeplot
	language : 'en', // default language of GeoTemCo
	allowFilter : true, // if filtering should be allowed
	highlightEvents : true, // if updates after highlight events
	selectionEvents : true, // if updates after selection events
	tableExportDataset : true, // export dataset to KML 
	allowCustomColoring : false, // if DataObjects can have an own color (useful for weighted coloring)
	allowUserShapeAndColorChange: false, // if the user can change the shapes and color of datasets 
										// this turns MapConfig.useGraphics auto-on, but uses circles as default
	loadColorFromDataset : false, // if DataObject color should be loaded automatically (from column "color")
	allowColumnRenaming : true,
	//proxy : '', //set this if a HTTP proxy shall be used (e.g. to bypass X-Domain problems)
	//colors for several datasets; rgb1 will be used for selected objects, rgb0 for unselected
	colors : [{
		r1 : 255,
		g1 : 101,
		b1 : 0,
		r0 : 253,
		g0 : 229,
		b0 : 205
	}, {
		r1 : 144,
		g1 : 26,
		b1 : 255,
		r0 : 230,
		g0 : 225,
		b0 : 255
	}, {
		r1 : 0,
		g1 : 217,
		b1 : 0,
		r0 : 213,
		g0 : 255,
		b0 : 213
	}, {
		r1 : 240,
		g1 : 220,
		b1 : 0,
		r0 : 247,
		g0 : 244,
		b0 : 197
	}]

}

GeoTemConfig.ie = false;
GeoTemConfig.ie8 = false;

GeoTemConfig.independentMapId = 0;
GeoTemConfig.independentTimeId = 0;

if (/MSIE (\d+\.\d+);/.test(navigator.userAgent)) {
	GeoTemConfig.ie = true;
	var ieversion = new Number(RegExp.$1);
	if (ieversion == 8) {
		GeoTemConfig.ie8 = true;
	}
}

GeoTemConfig.getIndependentId = function(target){
	if( target == 'map' ){
		return ++GeoTemConfig.independentMapId;
	}
	if( target == 'time' ){
		return ++GeoTemConfig.independentTimeId;
	}
	return 0;
};

GeoTemConfig.setHexColor = function(hex,index,fill){
	var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
	if( fill ){
		GeoTemConfig.colors[index].r0 = parseInt(result[1], 16);
		GeoTemConfig.colors[index].g0 = parseInt(result[2], 16);
		GeoTemConfig.colors[index].b0 = parseInt(result[3], 16);
	}
	else {
		GeoTemConfig.colors[index].r1 = parseInt(result[1], 16);
		GeoTemConfig.colors[index].g1 = parseInt(result[2], 16);
		GeoTemConfig.colors[index].b1 = parseInt(result[3], 16);
	}
}

GeoTemConfig.setRgbColor = function(r,g,b,index,fill){
	if( fill ){
		GeoTemConfig.colors[index].r0 = r;
		GeoTemConfig.colors[index].g0 = g;
		GeoTemConfig.colors[index].b0 = b;
	}
	else {
		GeoTemConfig.colors[index].r1 = r;
		GeoTemConfig.colors[index].g1 = g;
		GeoTemConfig.colors[index].b1 = b;
	}
}

GeoTemConfig.configure = function(urlPrefix) {
	GeoTemConfig.urlPrefix = urlPrefix;
	GeoTemConfig.path = GeoTemConfig.urlPrefix + "images/";
}

GeoTemConfig.applySettings = function(settings) {
	$.extend(this, settings);
};

//Keeps track of how many colors where assigned yet.
GeoTemConfig.assignedColorCount = 0;
GeoTemConfig.getColor = function(id){
	if (typeof GeoTemConfig.datasets[id].color === "undefined"){
		var color;
		
		while (true){
			if( GeoTemConfig.colors.length <= GeoTemConfig.assignedColorCount ){
				color = {
					r1 : Math.floor((Math.random()*255)+1),
					g1 : Math.floor((Math.random()*255)+1),
					b1 : Math.floor((Math.random()*255)+1),
					r0 : 230,
					g0 : 230,
					b0 : 230
				};
			} else
				color = GeoTemConfig.colors[GeoTemConfig.assignedColorCount];
			
			//make sure that no other dataset has this color
			//TODO: one could also check that they are not too much alike
			var found = false;
			for (var i = 0; i < GeoTemConfig.datasets.length; i++){
				var dataset = GeoTemConfig.datasets[i];
				
				if (typeof dataset.color === "undefined")
					continue;

				if (	(dataset.color.r1 == color.r1) && 
						(dataset.color.g1 == color.g1) &&
						(dataset.color.b1 == color.b1) ){
					found = true;
					break;
				}
			}
			if (found === true){
				if( GeoTemConfig.colors.length <= GeoTemConfig.assignedColorCount ){
					//next time skip over this color
					GeoTemConfig.assignedColorCount++;
				}
				continue;
			} else {
				GeoTemConfig.colors.push(color);
				break;
			}
		}
		GeoTemConfig.datasets[id].color = color;

		GeoTemConfig.assignedColorCount++;
	}
	return GeoTemConfig.datasets[id].color;
};

GeoTemConfig.getAverageDatasetColor = function(id, objects){
	var c = new Object();
	var datasetColor = GeoTemConfig.getColor(id);
	c.r0 = datasetColor.r0;
	c.g0 = datasetColor.g0;
	c.b0 = datasetColor.b0;
	c.r1 = datasetColor.r1;
	c.g1 = datasetColor.g1;
	c.b1 = datasetColor.b1;
	if (!GeoTemConfig.allowCustomColoring)
		return c;
	if (objects.length == 0)
		return c;
	var avgColor = new Object();
	avgColor.r0 = 0;
	avgColor.g0 = 0;
	avgColor.b0 = 0;
	avgColor.r1 = 0;
	avgColor.g1 = 0;
	avgColor.b1 = 0;
	
	$(objects).each(function(){
		if (this.hasColorInformation){
			avgColor.r0 += this.color.r0;
			avgColor.g0 += this.color.g0;
			avgColor.b0 += this.color.b0;
			avgColor.r1 += this.color.r1;
			avgColor.g1 += this.color.g1;
			avgColor.b1 += this.color.b1;
		} else {
			avgColor.r0 += datasetColor.r0;
			avgColor.g0 += datasetColor.g0;
			avgColor.b0 += datasetColor.b0;
			avgColor.r1 += datasetColor.r1;
			avgColor.g1 += datasetColor.g1;
			avgColor.b1 += datasetColor.b1;
		}
	});
	
	c.r0 = Math.floor(avgColor.r0/objects.length);
	c.g0 = Math.floor(avgColor.g0/objects.length);
	c.b0 = Math.floor(avgColor.b0/objects.length);
	c.r1 = Math.floor(avgColor.r1/objects.length);
	c.g1 = Math.floor(avgColor.g1/objects.length);
	c.b1 = Math.floor(avgColor.b1/objects.length);
	
	return c;
};

GeoTemConfig.getString = function(field) {
	if ( typeof Tooltips[GeoTemConfig.language] == 'undefined') {
		GeoTemConfig.language = 'en';
	}
	return Tooltips[GeoTemConfig.language][field];
}
/**
 * returns the actual mouse position
 * @param {Event} e the mouseevent
 * @return the top and left position on the screen
 */
GeoTemConfig.getMousePosition = function(e) {
	if (!e) {
		e = window.event;
	}
	var body = (window.document.compatMode && window.document.compatMode == "CSS1Compat") ? window.document.documentElement : window.document.body;
	return {
		top : e.pageY ? e.pageY : e.clientY,
		left : e.pageX ? e.pageX : e.clientX
	};
}
/**
 * returns the json object of the file from the given url
 * @param {String} url the url of the file to load
 * @return json object of given file
 */
GeoTemConfig.getJson = function(url,asyncFunc) {
	var async = false;
	if( asyncFunc ){
		async = true;
	}
	
	var data;
	$.ajax({
		url : url,
		async : async,
		dataType : 'json',
		success : function(json) {
			data = json;
			if (async){
				asyncFunc(data);
			}
		}
	});
	
	if (!async){
		return data;
	}
}

GeoTemConfig.mergeObjects = function(set1, set2) {
	var inside = [];
	var newSet = [];
	for (var i = 0; i < GeoTemConfig.datasets.length; i++){
		inside.push([]);
		newSet.push([]);
	}
	for (var i = 0; i < set1.length; i++) {
		for (var j = 0; j < set1[i].length; j++) {
			inside[i][set1[i][j].index] = true;
			newSet[i].push(set1[i][j]);
		}
	}
	for (var i = 0; i < set2.length; i++) {
		for (var j = 0; j < set2[i].length; j++) {
			if (!inside[i][set2[i][j].index]) {
				newSet[i].push(set2[i][j]);
			}
		}
	}
	return newSet;
};

GeoTemConfig.datasets = [];

GeoTemConfig.addDataset = function(newDataset){
	GeoTemConfig.datasets.push(newDataset);
	Publisher.Publish('filterData', GeoTemConfig.datasets, null);
};

GeoTemConfig.addDatasets = function(newDatasets){
	$(newDatasets).each(function(){
		GeoTemConfig.datasets.push(this);
	});	
	Publisher.Publish('filterData', GeoTemConfig.datasets, null);
};

GeoTemConfig.removeDataset = function(index){
	GeoTemConfig.datasets.splice(index,1);
	Publisher.Publish('filterData', GeoTemConfig.datasets, null);
};

/**
 * converts the csv-file into json-format
 * 
 * @param {String}
 *            text
 */
GeoTemConfig.convertCsv = function(text){
	/* convert here from CSV to JSON */
	var json = [];
	/* define expected csv table headers (first line) */
	var expectedHeaders = new Array("Name","Address","Description","Longitude","Latitude","TimeStamp","TimeSpan:begin","TimeSpan:end","weight");
	/* convert csv string to array of arrays using ucsv library */
	var csvArray = CSV.csvToArray(text);
	/* get real used table headers from csv file (first line) */
	var usedHeaders = csvArray[0];
	/* loop outer array, begin with second line */
	for (var i = 1; i < csvArray.length; i++) {
		var innerArray = csvArray[i];
		var dataObject = new Object();
		var tableContent = new Object(); 
		/* exclude lines with no content */
		var hasContent = false;
		for (var j = 0; j < innerArray.length; j++) {
			if (typeof innerArray[j] !== "undefined"){
				if (typeof innerArray[j] === "string"){
					if (innerArray[j].length > 0)
						hasContent = true;
				} else {
					hasContent = true;
				}
			}
			
			if (hasContent === true)
				break;
		}
		if (hasContent === false)
			continue;
	   	/* loop inner array */
		for (var j = 0; j < innerArray.length; j++) {
			/* Name */
			if (usedHeaders[j] == expectedHeaders[0]) {
				dataObject["name"] = ""+innerArray[j];
				tableContent["name"] = ""+innerArray[j];
			}
			/* Address */
			else if (usedHeaders[j] == expectedHeaders[1]) {
				dataObject["place"] = ""+innerArray[j];
				tableContent["place"] = ""+innerArray[j];
			}
			/* Description */
			else if (usedHeaders[j] == expectedHeaders[2]) {
				dataObject["description"] = ""+innerArray[j];
				tableContent["description"] = ""+innerArray[j];
			}
			/* TimeStamp */
			else if (usedHeaders[j] == expectedHeaders[5]) {
				dataObject["time"] = ""+innerArray[j];
			}
			/* TimeSpan:begin */
			else if (usedHeaders[j] == expectedHeaders[6]) {
				tableContent["TimeSpan:begin"] = ""+innerArray[j];
			}
			/* TimeSpan:end */
			else if (usedHeaders[j] == expectedHeaders[7]) {
				tableContent["TimeSpan:end"] = ""+innerArray[j];
			}   						
			/* weight */
			else if (usedHeaders[j] == expectedHeaders[8]) {
				dataObject["weight"] = ""+innerArray[j];
			}   						
			/* Longitude */                                                          
			else if (usedHeaders[j] == expectedHeaders[3]) {                              
				dataObject["lon"] = parseFloat(innerArray[j]);                                           
			}                                                                        
			/* Latitude */                                                           
			else if (usedHeaders[j] == expectedHeaders[4]) {                              
				dataObject["lat"] = parseFloat(innerArray[j]);
			}
			else {
				var header = new String(usedHeaders[j]);
				//remove leading and trailing Whitespace
				header = $.trim(header);
				tableContent[header] = ""+innerArray[j];
			}
		}
		
		dataObject["tableContent"] = tableContent;
		
		json.push(dataObject);
	}
	
	return json;
};

/**
 * returns the xml dom object of the file from the given url
 * @param {String} url the url of the file to load
 * @return xml dom object of given file
 */
GeoTemConfig.getKml = function(url,asyncFunc) {
	var data;
	var async = false;
	if( asyncFunc ){
		async = true;
	}
	$.ajax({
		url : url,
		async : async,
		dataType : 'xml',
		success : function(xml) {
			if( asyncFunc ){
				asyncFunc(xml);
			}
			else {
				data = xml;
			}
		}
	});
	if( !async ){
		return data;
	}
}

/**
 * returns an array of all xml dom object of the kmls 
 * found in the zip file from the given url
 * 
 * can only be used with asyncFunc (because of browser 
 * constraints regarding arraybuffer)
 * 
 * @param {String} url the url of the file to load
 * @return xml dom object of given file
 */
GeoTemConfig.getKmz = function(url,asyncFunc) {
	var kmlDom = new Array();

	var async = true;
	if( !asyncFunc ){
		//if no asyncFunc is given return an empty array
		return kmlDom;
	}
	
	//use XMLHttpRequest as "arraybuffer" is not 
	//supported in jQuery native $.get
    var req = new XMLHttpRequest();
    req.open("GET",url,async);
    req.responseType = "arraybuffer";
    req.onload = function() {
    	var zip = new JSZip();
    	zip.load(req.response, {base64:false});
    	var kmlFiles = zip.file(new RegExp("kml$"));
    	
    	$(kmlFiles).each(function(){
			var kml = this;
			if (kml.data != null) {
				kmlDom.push($.parseXML(kml.data));
			}
    	});
    	
    	asyncFunc(kmlDom);
    };
	req.send();
};

/**
 * returns the JSON "object"  
 * from the csv file from the given url
 * @param {String} url the url of the file to load
 * @return xml dom object of given file
 */
GeoTemConfig.getCsv = function(url,asyncFunc) {
	var async = false;
	if( asyncFunc ){
		async = true;
	}
	
	//use XMLHttpRequest as synchronous behaviour 
	//is not supported in jQuery native $.get
    var req = new XMLHttpRequest();
    req.open("GET",url,async);
    //can only be set on asynchronous now
    //req.responseType = "text";
    console.log(url);
    var json;
    req.onload = function() {
    	json = GeoTemConfig.convertCsv(req.response);
    	if( asyncFunc )
    		asyncFunc(json);
    };
	req.send();
	
	if( !async ){
		return json;
	}
};

/**
 * loads a binary file  
 * @param {String} url of the file to load
 * @return binary data
 */
GeoTemConfig.getBinary = function(url,asyncFunc) {
	var async = true;

	var req = new XMLHttpRequest();
    req.open("GET",url,async);
    req.responseType = "arraybuffer";
    
    var binaryData;
	req.onload = function() {
		var arrayBuffer = req.response;
		asyncFunc(arrayBuffer);
    };
	req.send();
};

/**
 * returns a Date and a SimileAjax.DateTime granularity value for a given XML time
 * @param {String} xmlTime the XML time as String
 * @return JSON object with a Date and a SimileAjax.DateTime granularity
 */
GeoTemConfig.getTimeData = function(xmlTime) {
	if (!xmlTime)
		return;
	var dateData;
	try {
		var bc = false;
		if (xmlTime.startsWith("-")) {
			bc = true;
			xmlTime = xmlTime.substring(1);
		}
		var timeSplit = xmlTime.split("T");
		var timeData = timeSplit[0].split("-");
		for (var i = 0; i < timeData.length; i++) {
			parseInt(timeData[i]);
		}
		if (bc) {
			timeData[0] = "-" + timeData[0];
		}
		if (timeSplit.length == 1) {
			dateData = timeData;
		} else {
			var dayData;
			if (timeSplit[1].indexOf("Z") != -1) {
				dayData = timeSplit[1].substring(0, timeSplit[1].indexOf("Z") - 1).split(":");
			} else {
				dayData = timeSplit[1].substring(0, timeSplit[1].indexOf("+") - 1).split(":");
			}
			for (var i = 0; i < timeData.length; i++) {
				parseInt(dayData[i]);
			}
			dateData = timeData.concat(dayData);
		}
	} catch (exception) {
		return null;
	}
	var date, granularity;
	if (dateData.length == 6) {
		granularity = SimileAjax.DateTime.SECOND;
		date = new Date(Date.UTC(dateData[0], dateData[1] - 1, dateData[2], dateData[3], dateData[4], dateData[5]));
	} else if (dateData.length == 3) {
		granularity = SimileAjax.DateTime.DAY;
		date = new Date(Date.UTC(dateData[0], dateData[1] - 1, dateData[2]));
	} else if (dateData.length == 2) {
		granularity = SimileAjax.DateTime.MONTH;
		date = new Date(Date.UTC(dateData[0], dateData[1] - 1, 1));
	} else if (dateData.length == 1) {
		granularity = SimileAjax.DateTime.YEAR;
		date = new Date(Date.UTC(dateData[0], 0, 1));
	}
	if (timeData[0] && timeData[0] < 100) {
		date.setFullYear(timeData[0]);
	}

	//check data validity;
	var isValidDate = true;
	if ( date instanceof Date ) {
		if ( isNaN( date.getTime() ) )
			isValidDate = false;
	} else
		isValidDate = false;
	
	if (!isValidDate){
		if ((GeoTemConfig.debug)&&(typeof console !== "undefined"))
			console.error(xmlTime + " is no valid time format");
		return null;
	}
	
	return {
		date : date,
		granularity : granularity
	};
}
/**
 * converts a JSON array into an array of data objects
 * @param {JSON} JSON a JSON array of data items
 * @return an array of data objects
 */
GeoTemConfig.loadJson = function(JSON) {
	var mapTimeObjects = [];
	var runningIndex = 0;
	for (var i in JSON ) {
		try {
			var item = JSON[i];
			var index = item.index || item.id || runningIndex++;
			var name = item.name || "";
			var description = item.description || "";
			var tableContent = item.tableContent || [];
			var locations = [];
			if (item.location instanceof Array) {
				for (var j = 0; j < item.location.length; j++) {
					var place = item.location[j].place || "unknown";
					var lon = item.location[j].lon;
					var lat = item.location[j].lat;
					if ((typeof lon === "undefined" || typeof lat === "undefined" || isNaN(lon) || isNaN(lat) ) && !GeoTemConfig.incompleteData) {
						throw "e";
					}
					locations.push({
						longitude : lon,
						latitude : lat,
						place : place
					});
				}
			} else {
				var place = item.place || "unknown";
				var lon = item.lon;
				var lat = item.lat;
				if ((typeof lon === "undefined" || typeof lat === "undefined" || isNaN(lon) || isNaN(lat) ) && !GeoTemConfig.incompleteData) {
					throw "e";
				}
				locations.push({
					longitude : lon,
					latitude : lat,
					place : place
				});
			}
			var dates = [];
			if (item.time instanceof Array) {
				for (var j = 0; j < item.time.length; j++) {
					var time = GeoTemConfig.getTimeData(item.time[j]);
					if (time == null && !GeoTemConfig.incompleteData) {
						throw "e";
					}
					dates.push(time);
				}
			} else {
				var time = GeoTemConfig.getTimeData(item.time);
				if (time == null && !GeoTemConfig.incompleteData) {
					throw "e";
				}
				if (time != null) {
					dates.push(time);
				}
			}
			var weight = parseInt(item.weight) || 1;
			//add all "other" attributes to table data
			//this is a hack to allow "invalid" JSONs
			var specialAttributes = ["id", "name", "description", "lon", "lat", "place", "time", 
			                        "tableContent", "location", "time"];
			for (var attribute in item){
				if ($.inArray(attribute, specialAttributes) == -1){
					tableContent[attribute] = item[attribute];
				}
			}
			
			var mapTimeObject = new DataObject(name, description, locations, dates, weight, tableContent);
			mapTimeObject.setIndex(index);
			mapTimeObjects.push(mapTimeObject);
		} catch(e) {
			continue;
		}
	}

	if (GeoTemConfig.loadColorFromDataset)
		GeoTemConfig.loadDataObjectColoring(mapTimeObjects);

	return mapTimeObjects;
}
/**
 * converts a KML dom into an array of data objects
 * @param {XML dom} kml the XML dom for the KML file
 * @return an array of data objects
 */
GeoTemConfig.loadKml = function(kml) {
	var mapObjects = [];
	var elements = kml.getElementsByTagName("Placemark");
	if (elements.length == 0) {
		return [];
	}
	var index = 0;
	var descriptionTableHeaders = [];
	var xmlSerializer = new XMLSerializer();	
	
	for (var i = 0; i < elements.length; i++) {
		var placemark = elements[i];
		var name, description, place, granularity, lon, lat, tableContent = [], time = [], location = [];
		var weight = 1;
		var timeData = false, mapData = false;

		try {
			description = placemark.getElementsByTagName("description")[0].childNodes[0].nodeValue;
			
			//cleanWhitespace removes non-sense text-nodes (space, tab)
			//and is an addition to jquery defined above
			try {
				var descriptionDocument = $($.parseXML(description)).cleanWhitespace();
				
				//check whether the description element contains a table
				//if yes, this data will be loaded as separate columns
				$(descriptionDocument).find("table").each(function(){
					$(this).find("tr").each(
						function() {
							var isHeader = true;
							var lastHeader = "";
							
							$(this).find("td").each(
								function() {
									if (isHeader) {
										lastHeader = $.trim($(this).text());
										isHeader = false;
									} else {
										var value = "";
	
										//if this td contains HTML, serialize all
										//it's children (the "content"!)
										$(this).children().each(
											function() {
												value += xmlSerializer.serializeToString(this);
											}
										);
										
										//no HTML content (or no content at all)
										if (value.length == 0)
											value = $(this).text();
										if (typeof value === "undefined")
											value = "";
										
										if ($.inArray(lastHeader, descriptionTableHeaders) === -1)
											descriptionTableHeaders.push(lastHeader);
	
										if (tableContent[lastHeader] != null)
											//append if a field occures more than once 
											tableContent[lastHeader] += "\n" + value;
										else
											tableContent[lastHeader] = value;
	
										isHeader = true;
									}
								}
							);
						}
					);
				});
			} catch(e) {
				//couldn't be parsed, so it contains no html table
				//or is not in valid XHTML syntax
			}
			
			//check whether the description element contains content in the form of equations
			//e.g. someDescriptor = someValue, where these eqations are separated by <br/>
			//if yes, this data will be loaded as separate columns
			var descriptionRows = description.replace(/<\s*br\s*[\/]*\s*>/g,"<br/>"); 
			$(descriptionRows.split("<br/>")).each(function(){
				var row = this;
				
				if (typeof row === "undefined")
					return;
				
				var headerAndValue = row.split("=");
				if (headerAndValue.length != 2)
					return;

				var header = $.trim(headerAndValue[0]);
				var value = $.trim(headerAndValue[1]);
				
				if ($.inArray(header, descriptionTableHeaders) === -1)
					descriptionTableHeaders.push(header);

				if (tableContent[header] != null)
					//append if a field occures more than once 
					tableContent[header] += "\n" + value;
				else
					tableContent[header] = value;
			});

			tableContent["description"] = description;
		} catch(e) {
			description = "";
		}

		try {
			name = placemark.getElementsByTagName("name")[0].childNodes[0].nodeValue;
			tableContent["name"] = name;
		} catch(e) {
			if (typeof tableContent["name"] !== "undefined")
				name = tableContent["name"];
			else
				name = "";
		}		

		try {
			place = placemark.getElementsByTagName("address")[0].childNodes[0].nodeValue;
			tableContent["place"] = place;
		} catch(e) {
			if (typeof tableContent["place"] !== "undefined")
				place = tableContent["place"];
			else
				place = "";
		}

		try {
			var coordinates = placemark.getElementsByTagName("Point")[0].getElementsByTagName("coordinates")[0].childNodes[0].nodeValue;
			var lonlat = coordinates.split(",");
			lon = lonlat[0];
			lat = lonlat[1];
			if (lon == "" || lat == "" || isNaN(lon) || isNaN(lat)) {
				throw "e";
			}
			location.push({
				longitude : lon,
				latitude : lat,
				place : place
			});
		} catch(e) {
			if (!GeoTemConfig.incompleteData) {
				continue;
			}
		}

		try {
			var tuple = GeoTemConfig.getTimeData(placemark.getElementsByTagName("TimeStamp")[0].getElementsByTagName("when")[0].childNodes[0].nodeValue);
			if (tuple != null) {
				time.push(tuple);
				timeData = true;
			} else if (!GeoTemConfig.incompleteData) {
				continue;
			}
		} catch(e) {
			try {
				if (	(typeof tableContent["TimeSpan:begin"] === "undefined") &&
						(typeof tableContent["TimeSpan:end"] === "undefined") ){
					var timeStart = $(placemark).find("TimeSpan begin").text();
					var timeEnd = $(placemark).find("TimeSpan end").text();
					
					if ( (timeStart != "") && (timeStart != "") ){
						tableContent["TimeSpan:begin"] = timeStart;
						tableContent["TimeSpan:end"] = timeEnd;

						timeData = true;
					}
				}
			} catch(e) {
				if (!GeoTemConfig.incompleteData) {
					continue;
				}
			}
		}
		var object = new DataObject(name, description, location, time, 1, tableContent);
		object.setIndex(index);
		index++;
		mapObjects.push(object);
	}
	
	//make sure that all "description table" columns exists in all rows
	if (descriptionTableHeaders.length > 0){
		$(mapObjects).each(function(){
			var object = this;
			$(descriptionTableHeaders).each(function(){
				if (typeof object.tableContent[this] === "undefined")
					object.tableContent[this] = "";
			});
		});
	}

	if (GeoTemConfig.loadColorFromDataset)
		GeoTemConfig.loadDataObjectColoring(mapObjects);

	return mapObjects;
};

GeoTemConfig.createKMLfromDataset = function(index){
	var kmlContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><kml xmlns=\"http://www.opengis.net/kml/2.2\"><Document>";

	//credits: Anatoly Mironov, http://stackoverflow.com/questions/2573521/how-do-i-output-an-iso-8601-formatted-string-in-javascript
	function pad(number) {
		var r = String(number);
		if ( r.length === 1 ) {
			r = '0' + r;
		}
		return r;
	}

	var dateToISOString = function(date, granularity) {
		var ISOString = date.getFullYear();

		if (granularity <= SimileAjax.DateTime.MONTH)
			ISOString += '-' + pad( date.getMonth() + 1 );
		if (granularity <= SimileAjax.DateTime.DAY)
			ISOString += '-' + pad( date.getDate() );
		if (granularity <= SimileAjax.DateTime.HOUR){
			ISOString += 'T' + pad( date.getHours() );
			if (granularity <= SimileAjax.DateTime.MINUTE)
				ISOString += ':' + pad( date.getMinutes() );
			if (granularity <= SimileAjax.DateTime.SECOND)
				ISOString += ':' + pad( date.getSeconds() );
			if (granularity <= SimileAjax.DateTime.MILLISECOND)
				ISOString += '.' + String( (date.getMilliseconds()/1000).toFixed(3) ).slice( 2, 5 );
			ISOString += 'Z';
		}
		
		return ISOString;
	};
      
	$(GeoTemConfig.datasets[index].objects).each(function(){
		var name = this.name;
		var description = this.description;
		//TODO: allow multiple time/date
		var place = this.getPlace(0,0);
		var lat = this.getLatitude(0);
		var lon = this.getLongitude(0);
		
		var kmlEntry = "<Placemark>";
		
		kmlEntry += "<name><![CDATA[" + name + "]]></name>";
		kmlEntry += "<address><![CDATA[" + place + "]]></address>";
		kmlEntry += "<description><![CDATA[" + description + "]]></description>";
		kmlEntry += "<Point><coordinates>" + lon + "," + lat + "</coordinates></Point>";
		  
		if (this.isTemporal){
			kmlEntry += "<TimeStamp><when>" + dateToISOString(this.getDate(0), this.getTimeGranularity(0)) + "</when></TimeStamp>";
		} else if (this.isFuzzyTemporal){
			kmlEntry +=	"<TimeSpan>"+
							"<begin>" + dateToISOString(this.TimeSpanBegin.utc().toDate(), this.TimeSpanBeginGranularity) + "</begin>" +
							"<end>" + dateToISOString(this.TimeSpanEnd.utc().toDate(), this.TimeSpanEndGranularity) + "</end>" +
						"</TimeSpan>";
		}
		
		kmlEntry += "</Placemark>";
		      
		kmlContent += kmlEntry;
	});
	  
	kmlContent += "</Document></kml>";
	  
	return(kmlContent);
};

GeoTemConfig.createCSVfromDataset = function(index){
	var csvContent = "";
	var header = ["name", "description", "weight"];
	var tableContent = [];
	
	var firstDataObject = GeoTemConfig.datasets[index].objects[0];
	
	for(var key in firstDataObject.tableContent){
		var found = false;
		$(header).each(function(index,val){
			if (val === key){
				found = true;
				return false;
			}				
		});
		if (found === true)
			continue;
		else
			tableContent.push(key);
	}
	
	var isFirst = true;
	$(header).each(function(key,val){
		if (isFirst){
			isFirst = false;
		} else {
			csvContent += ",";
		}

		//Rename according to CSV import definition
		if (val === "name")
			val = "Name";
		else if (val === "description")
			val = "Description";
		csvContent += "\""+val+"\"";
	});
	$(tableContent).each(function(key,val){
		if (isFirst){
			isFirst = false;
		} else {
			csvContent += ",";
		}
		csvContent += "\""+val+"\"";
	});
	//Names according to CSV import definition
	csvContent +=  ",\"Address\",\"Latitude\",\"Longitude\",\"TimeStamp\"";
	csvContent += "\n";
	
	var isFirstRow = true;
	$(GeoTemConfig.datasets[index].objects).each(function(){
		var elem = this;
		
		if (isFirstRow){
			isFirstRow = false;
		} else {
			csvContent += "\n";
		}
		
		var isFirst = true;
		$(header).each(function(key,val){
			if (isFirst){
				isFirst = false;
			} else {
				csvContent += ",";
			}
			csvContent += "\""+elem[val]+"\"";
		});
		$(tableContent).each(function(key,val){
			if (isFirst){
				isFirst = false;
			} else {
				csvContent += ",";
			}
			csvContent += "\""+elem.tableContent[val]+"\"";
		});
		
		csvContent += ",";
		csvContent += "\"";
		if (elem.isGeospatial){
			csvContent += elem.locations[0].place;
		}
		csvContent += "\"";

		csvContent += ",";
		csvContent += "\"";
		if ( (elem.isGeospatial) && (typeof elem.getLatitude(0) !== "undefined") ){
			csvContent += elem.getLatitude(0);
		}
		csvContent += "\"";

		csvContent += ",";
		csvContent += "\"";
		if ( (elem.isGeospatial) && (typeof elem.getLongitude(0) !== "undefined") ){
			csvContent += elem.getLongitude(0);
		}
		csvContent += "\"";
		
		csvContent += ",";
		csvContent += "\"";
		if ( (elem.isTemporal) && (typeof elem.getDate(0) !== "undefined") ){
			//TODO: not supported in IE8 switch to moment.js
			csvContent += elem.getDate(0).toISOString();
		}
		csvContent += "\"";
	});
	  
	return(csvContent);
};
/**
 * iterates over Datasets/DataObjects and loads color values
 * from the "color0" and "color1" elements, which contains RGB
 * values in hex (CSS style #RRGGBB)
 * @param {dataObjects} array of DataObjects
 */
GeoTemConfig.loadDataObjectColoring = function(dataObjects) {
	$(dataObjects).each(function(){
		var r0,g0,b0,r1,g1,b1;
		if (	(typeof this.tableContent !== "undefined") &&
				(typeof this.tableContent["color0"] !== "undefined") ){
			var color = this.tableContent["color0"];
			if ( (color.indexOf("#") == 0) && (color.length == 7) ){
			    r0 = parseInt("0x"+color.substr(1,2));
			    g0 = parseInt("0x"+color.substr(3,2));
			    b0 = parseInt("0x"+color.substr(5,2));
			}
		}
		if (	(typeof this.tableContent !== "undefined") &&
				(typeof this.tableContent["color1"] !== "undefined") ){
			var color = this.tableContent["color1"];
			if ( (color.indexOf("#") == 0) && (color.length == 7) ){
			    r1 = parseInt("0x"+color.substr(1,2));
			    g1 = parseInt("0x"+color.substr(3,2));
			    b1 = parseInt("0x"+color.substr(5,2));
			}
		}
		
		if (	(typeof r0 !== "undefined") && (typeof g0 !== "undefined") && (typeof b0 !== "undefined") &&
				(typeof r1 !== "undefined") && (typeof g1 !== "undefined") && (typeof b1 !== "undefined") ){
			this.setColor(r0,g0,b0,r1,g1,b1);
			delete this.tableContent["color0"];
			delete this.tableContent["color1"];
		} else {
			if ((GeoTemConfig.debug)&&(typeof console !== undefined))
				console.error("Object '" + this.name + "' has invalid color information");
		}
	});
};

/**
 * renames (or copies, see below) a column of each DataObject in a Dataset
 * @param {Dataset} dataset the dataset where the rename should take place
 * @param {String} oldColumn name of column that will be renamed
 * @param {String} newColumn new name of column
 * @param {Boolean} keepOld keep old column (copy mode)
 * @return an array of data objects
 */
GeoTemConfig.renameColumns = function(dataset, renames){
	if (renames.length===0){
		return;
	}
	for (var renCnt = 0; renCnt < renames.length; renCnt++){
		var oldColumn = renames[renCnt].oldColumn;
		var newColumn = renames[renCnt].newColumn;

		var keepOld = renames[renCnt].keepOld;
		if (typeof keepOld === "undefined"){
			keepOld = true;
		}
		var oldColumObject = {};
		if (oldColumn.indexOf("[") != -1){
			oldColumObject.columnName = oldColumn.split("[")[0];
			var IndexAndAttribute = oldColumn.split("[")[1];
			if (IndexAndAttribute.indexOf("]") != -1){
				oldColumObject.type = 2;
				oldColumObject.arrayIndex = IndexAndAttribute.split("]")[0];
				var attribute = IndexAndAttribute.split("]")[1];
				if (attribute.length > 0){
					oldColumObject.type = 3;
					oldColumObject.attribute = attribute.split(".")[1];
				}
			}
		} else {
			oldColumObject.type = 1;
			oldColumObject.name = oldColumn;
		}

		var newColumObject = {};
		if (newColumn.indexOf("[") != -1){
			newColumObject.name = newColumn.split("[")[0];
			var IndexAndAttribute = newColumn.split("[")[1];
			if (IndexAndAttribute.indexOf("]") != -1){
				newColumObject.type = 2;
				newColumObject.arrayIndex = IndexAndAttribute.split("]")[0];
				var attribute = IndexAndAttribute.split("]")[1];
				if (attribute.length > 0){
					newColumObject.type = 3;
					newColumObject.attribute = attribute.split(".")[1];
				}
			}
		} else {
			newColumObject.type = 1;
			newColumObject.name = newColumn;
		}

		for (var i = 0; i < dataset.objects.length; i++){
			var dataObject = dataset.objects[i];
			
			//get value from old column name
			var value;
			if (oldColumObject.type == 1){
				value = dataObject[oldColumObject.name];
				if (typeof value === "undefined"){
					value = dataObject.tableContent[oldColumObject.name];
				}
				if (!keepOld){
					delete dataObject.tableContent[oldColumObject.name];
					delete dataObject[oldColumObject.name];
				}
			} else if (oldColumObject.type == 2){
				value = dataObject[oldColumObject.name][oldColumObject.arrayIndex];
				if (!keepOld){
					delete dataObject[oldColumObject.name][oldColumObject.arrayIndex];
				}
			} else if (oldColumObject.type == 3){
				value = dataObject[oldColumObject.name][oldColumObject.arrayIndex][oldColumObject.attribute];
				if (!keepOld){
					delete dataObject[oldColumObject.name][oldColumObject.arrayIndex][oldColumObject.attribute];
				}
			} 

			//create new column
			if (newColumObject.type == 1){
				dataObject[newColumObject.name] = value;
				dataObject.tableContent[newColumObject.name] = value;
			} else if (newColumObject.type == 2){
				if (typeof dataObject[newColumObject.name] == "undefined"){
					dataObject[newColumObject.name] = [];
				}
				dataObject[newColumObject.name][newColumObject.arrayIndex] = value;
			} else if (newColumObject.type == 3){
				if (typeof dataObject[newColumObject.name] == "undefined"){
					dataObject[newColumObject.name] = [];
				}
				if (typeof dataObject[newColumObject.name][newColumObject.arrayIndex] == "undefined"){
					dataObject[newColumObject.name][newColumObject.arrayIndex] = {};
				}
				dataObject[newColumObject.name][newColumObject.arrayIndex][newColumObject.attribute] = value; 
			}
		}
	}

	//actually create new dataObjects
	for (var i = 0; i < dataset.objects.length; i++){
		var dataObject = dataset.objects[i];
		//save index
		var index = dataObject.index;

		dataset.objects[i] = new DataObject(dataObject.name, dataObject.description, dataObject.locations, 
			dataObject.dates, dataObject.weight, dataObject.tableContent, dataObject.projection);
		//set index
		dataset.objects[i].setIndex(index);
	}
};