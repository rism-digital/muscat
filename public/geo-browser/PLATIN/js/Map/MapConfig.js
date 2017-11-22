/*
* MapConfig.js
*
* Copyright © 2012, Stefan Jänicke. All rights reserved.
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
 * @class MapConfig
 * Map Configuration File
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
function MapConfig(options) {

	var gsurl = 'http://ref.dariah.eu/geoserver';
	var mpiwgurl = 'http://geoserver.mpiwg-berlin.mpg.de/geoserver';

	this.options = {
		mapWidth : false, // false or desired width css definition for the map
		mapHeight : '580px', // false or desired height css definition for the map
		mapTitle : 'GeoTemCo Map View', // title will be shown in map header
		mapIndex : 0, // index = position in location array; for multiple locations the 2nd map refers to index 1
		alternativeMap :  [
				{
					name: '-----------------------------------',
				},
				{
					name: 'Contemporary map 2014',
					url: gsurl + '/eurostat/wms',
					layer: 'eurostat:CNTR_RG_03M_2014',
					attribution: "© <a href='http://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units'>EuroGeographics for the administrative boundaries</a>"
				},
				{
					name: 'Contemporary map 2013',
					url: gsurl + '/eurostat/wms',
					layer: 'eurostat:CNTR_RG_03M_2013',
					attribution: "© <a href='http://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units'>EuroGeographics for the administrative boundaries</a>"
				},
				{
					name: '-----------------------------------',
				},
				{
					name: 'Maps-for-Free relief map',
					url: 'http://maps-for-free.com/layer/relief/z${z}/row${y}/${z}_${x}-${y}.jpg',
					type:'XYZ',
					attribution: "© <a href='http://www.maps-for-free.com/html/about.html'>Maps for Free</a>"
				},
				{
					name: 'Barrington Roman Empire',
					url: 'http://pelagios.org/tilesets/imperium/${z}/${x}/${y}.png',
					type:'XYZ',
					attribution: "© <a href='https://twitter.com/johanahlfeldt'>Johan Åhlfeldt</a>, <a href='http://commons.pelagios.org/'>Pelagios</a> (<a href='http://pelagios.org/maps/greco-roman/about.html'>Digital Atlas of the Roman Empire</a>)"
				},
				{
					name: '-----------------------------------',
				},
				{
					name: 'Historical map of 2010',
					url: gsurl + '/eurostat/wms',
					layer: 'eurostat:CNTR_RG_03M_2010',
					attribution: "© <a href='http://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units'>EuroGeographics for the administrative boundaries</a>"
				},
				{
					name: 'Historical map of 2006',
					url: gsurl + '/eurostat/wms',
					layer: 'eurostat:CNTR_RG_03M_2006 ',
					attribution: "© <a href='http://ec.europa.eu/eurostat/web/gisco/geodata/reference-data/administrative-units-statistical-units'>EuroGeographics for the administrative boundaries</a>"
				},
				{
					name: 'Historical map of 1994',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1994',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1949',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1949',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1938',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1938',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1920',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1920',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1914',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1914',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1880',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1880',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1815',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1815',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1783',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1783',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1715',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1715',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1650',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1650',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1530',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1530',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1492',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1492',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1279',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1279',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1000',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1000',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 800',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry800',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 600',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry600',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 400',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry400',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1 BC',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1bc',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 200 BC',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry200bc',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 323 BC',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry323bc',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 500 BC',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry500bc',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 1000 BC',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry1000bc',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
				{
					name: 'Historical map of 2000 BC',
					url: gsurl + '/historic/wms',
					layer: 'historic:cntry2000bc',
					attribution: "© <a href='https://web.archive.org/web/20091012051813/http://library.thinkquest.org/C006628'>ThinkQuest Team C006628</a>"
				},
//				{
//					name: '-----------------------------------',
//				},
//				{
//					name: 'CSHAPE borders 1994-12-15',
//					url: mpiwgurl + '/mpiwg/wms',
//					layer: 'mpiwg:borders_1994_12_15',
//					attribution: "© <a href='++TODO++'>++TODO++</a>"
//				},
//				{
//					name: 'Historical map 1957-03-06',
//					url: gsurl + '/mpiwg/wms',
//					layer: 'mpiwg:borders_1957_3_6Polygon',
//					attribution: "© <a href='++TODO++'>++TODO++</a>"
//				},
		],
		legend : true, // if a legend at the bottom of the map should be shown or not
		mapMerge : false, // if the elements of distinct datasets should be merged into one set or not
		useGraphics : false,  // if different graphics should represent different datasets or not
		graphics : [
			{
				shape: "circle",
				rotation: 0
			},
			{
				shape: "square",
				rotation: 0
			},
			{
				shape: "triangle",
				rotation: 0
			},
			{
				shape: "square",
				rotation: 45
			}
		],
		googleMaps : false, // enable/disable Google maps (actually, no Google Maps API key is required)
		bingMaps : false, // enable/disable Bing maps (you need to set the Bing Maps API key below)
		bingApiKey : 'none', // bing maps api key, see informations at http://bingmapsportal.com/
		osmMaps : true, // enable/disable OSM maps
		osmMapsMapQuest : false, // enable/disable OSM maps with MapQuest tiles
		baseLayer : 'Open Street Map', // initial layer to show (e.g. 'Google Streets')
		resetMap : true, // show/hide map reset button
		countrySelect : true, // show/hide map country selection control button
		polygonSelect : true, // show/hide map polygon selection control button
		circleSelect : true, // show/hide map circle selection control button
		squareSelect : true, // show/hide map square selection control button
		multiSelection : true, // true, if multiple polygons or multiple circles should be selectable
		popups : true, // enabled popups will show popup windows for circles on the map
		olNavigation : false, // show/hide OpenLayers navigation panel
		olLayerSwitcher : false, // show/hide OpenLayers layer switcher
		olMapOverview : false, // show/hide OpenLayers map overview
		olKeyboardDefaults : true, // (de)activate Openlayers keyboard defaults
		olScaleLine : false, // (de)activate Openlayers keyboard defaults
		geoLocation : true, // show/hide GeoLocation feature
		boundaries : {
			minLon : -29,
			minLat : 35,
			maxLon : 44,
			maxLat : 67
		}, // initial map boundaries or 'false' for no boundaries
		// mapBackground : '#bbd0ed',
		mapBackground : '#68635d',
		labelGrid : true, // show label grid on hover
		maxPlaceLabels : 6, // Integer value for fixed number of place labels: 0 --> unlimited, 1 --> 1 label (won't be shown in popup, 2 --> is not possible because of others & all labels --> 3 labels, [3,...,N] --> [3,...,N] place labels)
		selectDefault : true, // true, if strongest label should be selected as default
		maxLabelIncrease : 2, // maximum increase (in em) for the font size of a label
		labelHover : false, // true, to update on label hover
		ieHighlightLabel : "color: COLOR1; background-color: COLOR0; filter:'progid:DXImageTransform.Microsoft.Alpha(Opacity=80)';-ms-filter:'progid:DXImageTransform.Microsoft.Alpha(Opacity=80)';", // css code for a highlighted place label in IE
		highlightLabel : "color: COLOR0; text-shadow: 0 0 0.4em black, 0 0 0.4em black, 0 0 0.4em black, 0 0 0.4em COLOR0;", // css code for a highlighted place label
		ieSelectedLabel : "color: COLOR1; font-weight: bold;", // css code for a selected place label in IE
		selectedLabel : "color: COLOR1; font-weight: bold;", // css code for a selected place label
		ieUnselectedLabel : "color: COLOR1; font-weight: normal;", // css code for an unselected place label in IE
		unselectedLabel : "color: COLOR1; font-weight: normal;", // css code for an unselected place label
		ieHoveredLabel : "color: COLOR1; font-weight: bold;", // css code for a hovered place label in IE
		hoveredLabel : "color: COLOR1; font-weight: bold;", // css code for a hovered place label
		circleGap : 0, // gap between the circles on the map (>=0)
		circleOverlap : {
			type: 'area', // 'area' or 'diameter' is possible
			overlap: 0 // the percentage of allowed overlap (0<=overlap<=1)
		}, // maximum allowed overlap in percent (if circleGap = 0, circleOverlap will be used)
		minimumRadius : 4, // minimum radius of a circle with mimimal weight (>0)
		circleOutline : 2, // false for no outline or a pixel value v with 0 < v
		circleOpacity : 'balloon', // 'balloon' for dynamic opacity of the circles or a value t with 0 <= t <= 1
		minTransparency : 0.55, // maximum transparency of a circle
		maxTransparency : 0.8, // minimum transparency of a circle
		binning : 'generic', // binning algorithm for the map, possible values are: 'generic', 'square', 'hexagonal', 'triangular' or false for 'no binning'
		noBinningRadii : 'dynamic', // for 'no binning': 'static' for only minimum radii, 'dynamic' for increasing radii for increasing weights
		circlePackings : true, // if circles of multiple result sets should be displayed in circle packs, if a binning is performed
		binCount : 10, // number of bins for x and y dimension for lowest zoom level
		showDescriptions : true, // true to show descriptions of data items (must be provided by kml/json), false if not
		mapSelection : true, // show/hide select map dropdown
		binningSelection : false, // show/hide binning algorithms dropdown
		mapSelectionTools : true, // show/hide map selector tools
		dataInformation : true, // show/hide data information
		overlayVisibility : false, // initial visibility of additional overlays
		proxyHost : 'php/proxy.php?address=', //required for selectCountry feature, if the requested GeoServer and GeoTemCo are NOT on the same server
		placenameTagsStyle : 'value', // the style of the placenames "surrounding" a circle on hover. 'zoom' for tags based on zoom level (old behaviour), 'value' for new value-based
		hideUnselected : false //hide unselected circles (features) on highlight/selection

	};
	if ( typeof options != 'undefined') {
		$.extend(this.options, options);
	}
	
	//if the user can change shape/color graphics have to be used
	//but this will use circles as default shape
	if (GeoTemConfig.allowUserShapeAndColorChange){
		this.options.useGraphics = true;
	}

};

MapConfig.prototype.getGraphic = function(id){
	var dataset = GeoTemConfig.datasets[id];

	var graphic;
	if (typeof dataset.graphic !== "undefined"){
		graphic = dataset.graphic;
	} else{
		graphic = this.options.graphics[id % this.options.graphics.length];
	}
	
	var color;
	if (typeof dataset.color !== "undefined"){
		color = dataset.color;
	} else{
		// color = GeoTemConfig.getColor(id);
		color = GeoTemConfig.getColor(Math.floor(id/this.options.graphics.length))
	}
	return {
		shape: graphic.shape,
		rotation: graphic.rotation,
		color: color
	};
};
