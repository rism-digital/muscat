/*
* DataObject.js
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
 * @class DataObject
 * GeoTemCo's data object class
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {String} name name of the data object
 * @param {String} description description of the data object
 * @param {JSON} locations a list of locations with longitude, latitide and place name
 * @param {JSON} dates a list of dates
 * @param {float} lon longitude value of the given place
 * @param {float} lat latitude value of the given place
 * @param {Date} timeStart start time of the data object
 * @param {Date} timeEnd end time of the data object
 * @param {int} granularity granularity of the given time
 * @param {int} weight weight of the time object
 * @param {Openlayers.Projection} projection of the coordinates (optional)
 */

DataObject = function(name, description, locations, dates, weight, tableContent, projection) {

	this.name = $.trim(name);
	this.description = $.trim(description);
	this.weight = weight;
	this.tableContent = new Object();
	var objectTableContent = this.tableContent;
	for(key in tableContent){
		value = tableContent[key];
		objectTableContent[$.trim(key)]=$.trim(value);
	}

	this.percentage = 0;
	this.setPercentage = function(percentage) {
		this.percentage = percentage;
	}

	this.locations = [];
	var objectLocations = this.locations;
	$(locations).each(function(){
		objectLocations.push({
			latitude:this.latitude,
			longitude:this.longitude,
			place:$.trim(this.place)
		});
	});
	
	//Check if locations are valid
	if (!(projection instanceof OpenLayers.Projection)){
		//per default GeoTemCo uses WGS84 (-90<=lat<=90, -180<=lon<=180)
		projection = new OpenLayers.Projection("EPSG:4326");
	}
	this.projection = projection;

	var tempLocations = [];
	if (typeof this.locations !== "undefined"){
		$(this.locations).each(function(){
			//EPSG:4326 === WGS84
			this.latitude = parseFloat(this.latitude);
			this.longitude = parseFloat(this.longitude);
			if (projection.getCode() === "EPSG:4326"){
				if (	(typeof this.latitude === "number") &&
						(this.latitude>=-90) &&
						(this.latitude<=90) &&
						(typeof this.longitude === "number") &&
						(this.longitude>=-180) &&
						(this.longitude<=180) )
					tempLocations.push(this);
				else{
					if ((GeoTemConfig.debug)&&(typeof console !== undefined)){
							console.error("Object " + name + " has no valid coordinate. ("+this.latitude+","+this.longitude+")");						
					}
				}					
				
				//solve lat=-90 bug
				if( this.longitude == 180 ){
					this.longitude = 179.999;
				}
				if( this.longitude == -180 ){
					this.longitude = -179.999;
				}
				if( this.latitude == 90 ){
					this.latitude = 89.999;
				}
				if( this.latitude == -90 ){
					this.latitude = -89.999;
				}
			}
		});
		this.locations = tempLocations;
	}
	
	this.isGeospatial = false;
	if ((typeof this.locations !== "undefined") && (this.locations.length > 0)) {
		this.isGeospatial = true;
	}

	this.placeDetails = [];
	for (var i = 0; i < this.locations.length; i++) {
		this.placeDetails.push(this.locations[i].place.split("/"));
	}

	this.getLatitude = function(locationId) {
		return this.locations[locationId].latitude;
	}

	this.getLongitude = function(locationId) {
		return this.locations[locationId].longitude;
	}

	this.getPlace = function(locationId, level) {
		if (level >= this.placeDetails[locationId].length) {
			return this.placeDetails[locationId][this.placeDetails[locationId].length - 1];
		}
		return this.placeDetails[locationId][level];
	}

	this.dates = dates;
	this.isTemporal = false;
	if ((typeof this.dates !== "undefined") && (this.dates.length > 0)) {
		this.isTemporal = true;
		//test if we already have date "objects" or if we should parse the dates
		for (var i = 0; i < this.dates.length; i++){
			if (typeof this.dates[i] === "string"){
				var date = GeoTemConfig.getTimeData(this.dates[i]);
				//check whether we got valid dates
				if ((typeof date !== "undefined")&&(date != null)){
					this.dates[i] = date; 
				} else {
					//at least one date is invalid, so this dataObject has
					//no valid date information and is therefor not "temporal"
					this.isTemporal = false;
					break;
				}
			}
		}
	}

	//TODO: allow more than one timespan (as with dates/places)
	this.isFuzzyTemporal = false;
	if (this.isTemporal) {
		this.isTemporal = false;
		this.isFuzzyTemporal = true;
		
		var date = this.dates[0].date;
		var granularity = this.dates[0].granularity;
		
		this.TimeSpanGranularity = granularity;
		
		if (granularity === SimileAjax.DateTime.YEAR){
			this.TimeSpanBegin = moment(date).startOf("year");
			this.TimeSpanEnd = moment(date).endOf("year");
		} else if (granularity === SimileAjax.DateTime.MONTH){
			this.TimeSpanBegin = moment(date).startOf("month");
			this.TimeSpanEnd = moment(date).endOf("month");
		} else if (granularity === SimileAjax.DateTime.DAY){
			this.TimeSpanBegin = moment(date).startOf("day");
			this.TimeSpanEnd = moment(date).endOf("day");
		} else if (granularity === SimileAjax.DateTime.HOUR){
			this.TimeSpanBegin = moment(date).startOf("hour");
			this.TimeSpanEnd = moment(date).endOf("hour");
		} else if (granularity === SimileAjax.DateTime.MINUTE){
			this.TimeSpanBegin = moment(date).startOf("minute");
			this.TimeSpanEnd = moment(date).endOf("minute");
		} else if (granularity === SimileAjax.DateTime.SECOND){
			this.TimeSpanBegin = moment(date).startOf("second");
			this.TimeSpanEnd = moment(date).endOf("second");
		} else if (granularity === SimileAjax.DateTime.MILLISECOND){
			//this is a "real" exact time
			this.isTemporal = true;
			this.isFuzzyTemporal = false;
		}
	} else if (	(typeof this.tableContent["TimeSpan:begin"] !== "undefined") &&
				(typeof this.tableContent["TimeSpan:end"] !== "undefined") ){
		//parse according to ISO 8601
		//don't use the default "cross browser support" from moment.js
		//cause it won't work correctly with negative years
		var formats = [	"YYYYYY",
		               	"YYYYYY-MM",
		               	"YYYYYY-MM-DD",
		               	"YYYYYY-MM-DDTHH",
		               	"YYYYYY-MM-DDTHH:mm",
		               	"YYYYYY-MM-DDTHH:mm:ss",
		               	"YYYYYY-MM-DDTHH:mm:ss.SSS"
		               ];
		this.TimeSpanBegin = moment(this.tableContent["TimeSpan:begin"],formats.slice());
		this.TimeSpanEnd = moment(this.tableContent["TimeSpan:end"],formats.slice());
		if ((this.TimeSpanBegin instanceof Object) && this.TimeSpanBegin.isValid() && 
			(this.TimeSpanEnd instanceof Object) && this.TimeSpanEnd.isValid()){
			//check whether dates are correctly sorted
			if (this.TimeSpanBegin>this.TimeSpanEnd){
				//dates are in the wrong order
				if ((GeoTemConfig.debug)&&(typeof console !== undefined))
					console.error("Object " + this.name + " has wrong fuzzy dating (twisted start/end?).");
				
			} else {
				var timeSpanBeginGranularity = formats.indexOf(this.TimeSpanBegin._f);
				var timeSpanEndGranularity = formats.indexOf(this.TimeSpanEnd._f);
				var timeSpanGranularity = Math.max(	timeSpanBeginGranularity,
													timeSpanEndGranularity );

				//set granularity according to formats above
				if (timeSpanGranularity === 0){
					this.TimeSpanGranularity = SimileAjax.DateTime.YEAR;
				} else if (timeSpanGranularity === 1){
					this.TimeSpanGranularity = SimileAjax.DateTime.MONTH;
				} else if (timeSpanGranularity === 2){
					this.TimeSpanGranularity = SimileAjax.DateTime.DAY;
				} else if (timeSpanGranularity === 3){
					this.TimeSpanGranularity = SimileAjax.DateTime.HOUR;
				} else if (timeSpanGranularity === 4){
					this.TimeSpanGranularity = SimileAjax.DateTime.MINUTE;
				} else if (timeSpanGranularity === 5){
					this.TimeSpanGranularity = SimileAjax.DateTime.SECOND;
				} else if (timeSpanGranularity === 6){
					this.TimeSpanGranularity = SimileAjax.DateTime.MILLISECOND;
				}
				
				if (timeSpanBeginGranularity === 0){
					this.TimeSpanBeginGranularity = SimileAjax.DateTime.YEAR;
				} else if (timeSpanBeginGranularity === 1){
					this.TimeSpanBeginGranularity = SimileAjax.DateTime.MONTH;
				} else if (timeSpanBeginGranularity === 2){
					this.TimeSpanBeginGranularity = SimileAjax.DateTime.DAY;
				} else if (timeSpanBeginGranularity === 3){
					this.TimeSpanBeginGranularity = SimileAjax.DateTime.HOUR;
				} else if (timeSpanBeginGranularity === 4){
					this.TimeSpanBeginGranularity = SimileAjax.DateTime.MINUTE;
				} else if (timeSpanBeginGranularity === 5){
					this.TimeSpanBeginGranularity = SimileAjax.DateTime.SECOND;
				} else if (timeSpanBeginGranularity === 6){
					this.TimeSpanBeginGranularity = SimileAjax.DateTime.MILLISECOND;
				}
				
				if (timeSpanEndGranularity === 0){
					this.TimeSpanEndGranularity = SimileAjax.DateTime.YEAR;
				} else if (timeSpanEndGranularity === 1){
					this.TimeSpanEndGranularity = SimileAjax.DateTime.MONTH;
				} else if (timeSpanEndGranularity === 2){
					this.TimeSpanEndGranularity = SimileAjax.DateTime.DAY;
				} else if (timeSpanEndGranularity === 3){
					this.TimeSpanEndGranularity = SimileAjax.DateTime.HOUR;
				} else if (timeSpanEndGranularity === 4){
					this.TimeSpanEndGranularity = SimileAjax.DateTime.MINUTE;
				} else if (timeSpanEndGranularity === 5){
					this.TimeSpanEndGranularity = SimileAjax.DateTime.SECOND;
				} else if (timeSpanEndGranularity === 6){
					this.TimeSpanEndGranularity = SimileAjax.DateTime.MILLISECOND;
				}
				
				if (this.TimeSpanEnd.year()-this.TimeSpanBegin.year() >= 1000)
					this.TimeSpanGranularity = SimileAjax.DateTime.MILLENNIUM;
				else if (this.TimeSpanEnd.year()-this.TimeSpanBegin.year() >= 100)
					this.TimeSpanGranularity = SimileAjax.DateTime.CENTURY;
				else if (this.TimeSpanEnd.year()-this.TimeSpanBegin.year() >= 10)
					this.TimeSpanGranularity = SimileAjax.DateTime.DECADE;
				
				//also set upper bounds according to granularity
				//(lower bound is already correct)
				if (timeSpanEndGranularity === 0){
					this.TimeSpanEnd.endOf("year");
				} else if (timeSpanEndGranularity === 1){
					this.TimeSpanEnd.endOf("month");
				} else if (timeSpanEndGranularity === 2){
					this.TimeSpanEnd.endOf("day");
				} else if (timeSpanEndGranularity === 3){
					this.TimeSpanEnd.endOf("hour");
				} else if (timeSpanEndGranularity === 4){
					this.TimeSpanEnd.endOf("minute");
				} else if (timeSpanEndGranularity === 5){
					this.TimeSpanEnd.endOf("second");
				} else if (timeSpanEndGranularity === 6){
					//has max accuracy, so no change needed
				}

				this.isFuzzyTemporal = true;
			}
		}
	}

	
	this.getDate = function(dateId) {
		return this.dates[dateId].date;
	}

	this.getTimeGranularity = function(dateId) {
		return this.dates[dateId].granularity;
	}

	this.setIndex = function(index) {
		this.index = index;
	}

	this.getTimeString = function() {
		if (this.timeStart != this.timeEnd) {
			return (SimileAjax.DateTime.getTimeString(this.granularity, this.timeStart) + " - " + SimileAjax.DateTime.getTimeString(this.granularity, this.timeEnd));
		} else {
			return SimileAjax.DateTime.getTimeString(this.granularity, this.timeStart) + "";
		}
	};

	this.contains = function(text) {
		var allCombined = this.name + " " + this.description + " " + this.weight + " ";
		
		$.each(this.dates, function(key, value){
			$.each(value, function(){
				allCombined += this + " ";
			});
		});
		
		$.each(this.locations, function(key, value){
			$.each(value, function(){
				allCombined += this + " ";
			});
		});
		
		$.each(this.tableContent, function(key, value){
			allCombined += value + " ";
		});
		
		return (allCombined.indexOf(text) != -1);
	};
	
	this.hasColorInformation = false;
	
	this.setColor = function(r0,g0,b0,r1,g1,b1) {
		this.hasColorInformation = true;
		
		this.color = new Object();
		this.color.r0 = r0;
		this.color.g0 = g0;
		this.color.b0 = b0;
		this.color.r1 = r1;
		this.color.g1 = g1;
		this.color.b1 = b1;
	};

	this.getColor = function() {
		if (!this.hasColorInformation)
			return;
		
		color = new Object();
		color.r0 = this.r0;
		color.g0 = this.g0;
		color.b0 = this.b0;
		color.r1 = this.r1;
		color.g1 = this.g1;
		color.b1 = this.b1;
		
		return color;
	};
	
	Publisher.Publish('dataobjectAfterCreation', this);
};

