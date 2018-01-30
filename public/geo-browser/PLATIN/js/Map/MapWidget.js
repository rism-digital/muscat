/*
* MapWidget.js
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
 * @class MapWidget
 * MapWidget Implementation
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 *
 * @param {MapWrapper} core wrapper for interaction to other widgets
 * @param {HTML object} div parent div to append the map widget div
 * @param {JSON} options user specified configuration that overwrites options in MapConfig.js
 */
MapWidget = function(core, div, options) {

	this.core = core;
	this.core.setWidget(this);
	this.openlayersMap
	this.baseLayers
	this.objectLayer

	this.drawPolygon
	this.drawCircle
	this.selectCountry
	this.dragArea
	this.selectFeature
	this.navigation

	this.div = div;

	this.iid = GeoTemConfig.getIndependentId('map');
	this.config = new MapConfig(options);
	this.options = this.config.options;
	this.formerCP = this.options.circlePackings;
	this.gui = new MapGui(this, this.div, this.options, this.iid);

	this.initialize();

}

MapWidget.prototype = {

	/**
	 * initializes the map for the Spatio Temporal Interface.
	 * it includes setting up all layers of the map and defines all map specific interaction possibilities
	 */
	initialize : function() {

		var map = this;

		//OpenLayers.ProxyHost = "/cgi-bin/proxy.cgi?url=";
		if (map.options.proxyHost) {
			OpenLayers.ProxyHost = map.options.proxyHost;
		}

		this.polygons = [];
		this.connections = [];
		this.selection = new Selection();
		this.wmsOverlays = [];

		this.layerZIndex = 1;
		this.zIndices = [];

		var activateDrag = function() {
			map.dragArea.activate();
		}
		var deactivateDrag = function() {
			map.dragArea.deactivate();
		}
		this.dragControl = new MapControl(this, null, 'drag', activateDrag, deactivateDrag);

		/*
		 this.editPolygon = document.createElement("div");
		 this.editPolygon.title = GeoTemConfig.getString('editPolygon');
		 this.editPolygon.setAttribute('class','editMapPolygon');
		 this.toolbar.appendChild(this.editPolygon);
		 this.drag.onclick = function(evt){
		 if( map.activeControl == "drag" ){
		 map.deactivate("drag");
		 if( GeoTemConfig.navigate ){
		 map.activate("navigate");
		 }
		 }
		 else {
		 map.deactivate(map.activControl);
		 map.activate("drag");
		 }
		 }
		 map.addEditingMode(new OpenLayers.Control.EditingMode.PointArraySnapping());
		 */

		this.filterBar = new FilterBar(this, this.gui.filterOptions);

		this.objectLayer = new OpenLayers.Layer.Vector("Data Objects", {
			projection : "EPSG:4326",
			'displayInLayerSwitcher' : false,
			rendererOptions : {
				zIndexing : true
			}
		});

		this.markerLayer = new OpenLayers.Layer.Markers("Markers");

		this.navigation = new OpenLayers.Control.Navigation({
			zoomWheelEnabled : GeoTemConfig.mouseWheelZoom
		});
		this.navigation.defaultDblClick = function(evt) {
			var newCenter = this.map.getLonLatFromViewPortPx(evt.xy);
			this.map.setCenter(newCenter, this.map.zoom + 1);
			map.drawObjectLayer(false);
			if (map.zoomSlider) {
				map.zoomSlider.setValue(map.getZoom());
			}
		}
		this.navigation.wheelUp = function(evt) {
			this.wheelChange(evt, 1);
		}
		this.navigation.wheelDown = function(evt) {
			this.wheelChange(evt, -1);
		}

		this.resolutions = [78271.516953125, 39135.7584765625, 19567.87923828125, 9783.939619140625, 4891.9698095703125, 2445.9849047851562, 1222.9924523925781, 611.4962261962891, 305.74811309814453, 152.87405654907226, 76.43702827453613, 38.218514137268066, 19.109257068634033, 9.554628534317017, 4.777314267158508, 2.388657133579254, 1.194328566789627, 0.5971642833948135, 0.29858214169740677];

		var options = {
			controls : [this.navigation],
			projection : new OpenLayers.Projection("EPSG:900913"),
			displayProjection : new OpenLayers.Projection("EPSG:4326"),
			resolutions : this.resolutions,
			units : 'meters',
			maxExtent : new OpenLayers.Bounds(-20037508.34, -20037508.34, 20037508.34, 20037508.34)
		};
		this.openlayersMap = new OpenLayers.Map("mapContainer"+this.iid, options);
		if (map.options.navigate) {
			this.activeControl = "navigate";
		}
		//add attribution control
		this.openlayersMap.addControl(new OpenLayers.Control.Attribution());
		this.mds = new MapDataSource(this, this.options);

        //on zoomend, redraw objects and set slider (if it exists) accordingly (zoom by mouse wheel)
        this.openlayersMap.events.register("zoomend", map, function(){
            map.drawObjectLayer(false);
			if (map.zoomSlider) {
				map.zoomSlider.setValue(map.getZoom());
			}
			map.core.triggerHighlight([]);
        });

		if (map.options.olNavigation) {
			var zoomPanel = new OpenLayers.Control.PanZoom();
			zoomPanel.onButtonClick = function(evt) {
				var btn = evt.buttonElement;
				switch (btn.action) {
					case "panup":
						this.map.pan(0, -this.getSlideFactor("h"));
						break;
					case "pandown":
						this.map.pan(0, this.getSlideFactor("h"));
						break;
					case "panleft":
						this.map.pan(-this.getSlideFactor("w"), 0);
						break;
					case "panright":
						this.map.pan(this.getSlideFactor("w"), 0);
						break;
					case "zoomin":
						map.zoom(1);
						break;
					case "zoomout":
						map.zoom(-1);
						break;
					case "zoomworld":
						if (this.map) {
							map.zoom(this.map.zoom * -1);
						}
						break;
				}
			};
			this.openlayersMap.addControl(zoomPanel);
		}

		if (map.options.popups) {
			var panMap = function() {
				if (map.selectedGlyph) {
					var lonlat = new OpenLayers.LonLat(map.selectedGlyph.lon, map.selectedGlyph.lat);
					var pixel = map.openlayersMap.getPixelFromLonLat(lonlat);
					if (map.popup) {
						map.popup.shift(pixel.x, pixel.y);
					}
				}
			}
			this.openlayersMap.events.register("move", this.openlayersMap, panMap);
		}

		if (map.options.olMapOverview) {
			this.openlayersMap.addControl(new OpenLayers.Control.OverviewMap());
		}
		if (map.options.olKeyboardDefaults) {
			var keyboardControl = new OpenLayers.Control.KeyboardDefaults();
			keyboardControl.defaultKeyPress = function(evt) {
				switch(evt.keyCode) {
					case OpenLayers.Event.KEY_LEFT:
						this.map.pan(-this.slideFactor, 0);
						break;
					case OpenLayers.Event.KEY_RIGHT:
						this.map.pan(this.slideFactor, 0);
						break;
					case OpenLayers.Event.KEY_UP:
						this.map.pan(0, -this.slideFactor);
						break;
					case OpenLayers.Event.KEY_DOWN:
						this.map.pan(0, this.slideFactor);
						break;

					case 33:
						// Page Up. Same in all browsers.
						var size = this.map.getSize();
						this.map.pan(0, -0.75 * size.h);
						break;
					case 34:
						// Page Down. Same in all browsers.
						var size = this.map.getSize();
						this.map.pan(0, 0.75 * size.h);
						break;
					case 35:
						// End. Same in all browsers.
						var size = this.map.getSize();
						this.map.pan(0.75 * size.w, 0);
						break;
					case 36:
						// Home. Same in all browsers.
						var size = this.map.getSize();
						this.map.pan(-0.75 * size.w, 0);
						break;

					case 43:
					// +/= (ASCII), keypad + (ASCII, Opera)
					case 61:
					// +/= (Mozilla, Opera, some ASCII)
					case 187:
					// +/= (IE)
					case 107:
						// keypad + (IE, Mozilla)
						map.zoom(1);
						break;
					case 45:
					// -/_ (ASCII, Opera), keypad - (ASCII, Opera)
					case 109:
					// -/_ (Mozilla), keypad - (Mozilla, IE)
					case 189:
					// -/_ (IE)
					case 95:
						// -/_ (some ASCII)
						map.zoom(-1);
						break;
				}
			};
			this.openlayersMap.addControl(keyboardControl);
		}
		if (map.options.olLayerSwitcher) {
			this.openlayersMap.addControl(new OpenLayers.Control.LayerSwitcher());
		}
		if (map.options.olScaleLine) {
			this.openlayersMap.addControl(new OpenLayers.Control.ScaleLine());
		}
		this.gui.resize();
		this.setBaseLayers();
		this.gui.setMapsDropdown();
		this.gui.setMap();
		this.openlayersMap.addLayers([this.objectLayer, this.markerLayer]);

		if (map.options.boundaries) {
			var boundaries = map.options.boundaries;
			var bounds = new OpenLayers.Bounds(boundaries.minLon, boundaries.minLat, boundaries.maxLon, boundaries.maxLat);
			var projectionBounds = bounds.transform(this.openlayersMap.displayProjection, this.openlayersMap.projection);
			this.openlayersMap.zoomToExtent(projectionBounds);
		} else {
			this.openlayersMap.zoomToMaxExtent();
		}

		// manages selection of elements if a polygon was drawn
		this.drawnPolygonHandler = function(polygon) {
			if (map.mds.getAllObjects() == null) {
				return;
			}
			var polygonFeature;
			if ( polygon instanceof OpenLayers.Geometry.Polygon) {
				polygonFeature = new OpenLayers.Feature.Vector(new OpenLayers.Geometry.MultiPolygon([polygon]));
			} else if ( polygon instanceof OpenLayers.Geometry.MultiPolygon) {
				polygonFeature = new OpenLayers.Feature.Vector(polygon);
			}
			map.polygons.push(polygonFeature);
			var style = $.extend(true, {}, OpenLayers.Feature.Vector.style['default']);
			style.graphicZIndex = 0;
			polygonFeature.style = style;
			map.objectLayer.addFeatures([polygonFeature]);
			try {
				map.activeControl.deactivate();
			} catch(e) {
			}
			var circles = map.mds.getObjectsByZoom();
			for (var i = 0; i < circles.length; i++) {
				for (var j = 0; j < circles[i].length; j++) {
					var c = circles[i][j];
					if (map.inPolygon(c)) {
						if ( typeof c.fatherBin != 'undefined') {
							for (var k = 0; k < c.fatherBin.circles.length; k++) {
								if (c.fatherBin.circles[k]) {
									c.fatherBin.circles[k].setSelection(true);
								}
							}
						} else {
							c.setSelection(true);
						}
					}
				}
			}
			map.mapSelection();
		}

		this.polygonDeselection = function() {
			var circles = map.mds.getObjectsByZoom();
			for (var i = 0; i < circles.length; i++) {
				for (var j = 0; j < circles[i].length; j++) {
					var c = circles[i][j];
					if (map.inPolygon(c)) {
						c.setSelection(false);
					}
				}
			}
		}
		this.snapper = function() {
			if (map.polygons.length == 0 || !map.options.multiSelection) {
				map.deselection();
			}
		}
		if (map.options.polygonSelect) {
			this.drawPolygon = new OpenLayers.Control.DrawFeature(map.objectLayer, OpenLayers.Handler.Polygon, {
				displayClass : "olControlDrawFeaturePolygon",
				callbacks : {
					"done" : map.drawnPolygonHandler,
					"create" : map.snapper
				}
			});
			this.openlayersMap.addControl(this.drawPolygon);
		}

		if (map.options.circleSelect) {
			this.drawCircle = new OpenLayers.Control.DrawFeature(map.objectLayer, OpenLayers.Handler.RegularPolygon, {
				displayClass : "olControlDrawFeaturePolygon",
				handlerOptions : {
					sides : 40
				},
				callbacks : {
					"done" : map.drawnPolygonHandler,
					"create" : map.snapper
				}
			});
			this.openlayersMap.addControl(this.drawCircle);
		}

		if (map.options.squareSelect) {
			this.drawSquare = new OpenLayers.Control.DrawFeature(map.objectLayer, OpenLayers.Handler.RegularPolygon, {
				displayClass : "olControlDrawFeaturePolygon",
				handlerOptions : {
					sides : 4,
	                                irregular: true
				},
				callbacks : {
					"done" : map.drawnPolygonHandler,
					"create" : map.snapper
				}
			});
			this.openlayersMap.addControl(this.drawSquare);
		}

		if (map.options.polygonSelect || map.options.circleSelect || map.options.squareSelect) {
			this.dragArea = new OpenLayers.Control.DragFeature(map.objectLayer, {
				onStart : function(feature) {
					feature.style.graphicZIndex = 10000;
					map.polygonDeselection();
				},
				onComplete : function(feature) {
					feature.style.graphicZIndex = 0;
					map.drawnPolygonHandler(feature.geometry);
				}
			});
			this.openlayersMap.addControl(this.dragArea);

			this.modifyArea = new OpenLayers.Control.ModifyFeature(map.objectLayer, {
				onStart : function(feature) {
					feature.style.graphicZIndex = 10000;
					map.polygonDeselection();
				},
				onComplete : function(feature) {
					feature.style.graphicZIndex = 0;
					map.drawnPolygonHandler(feature.geometry);
				}
			});
			this.openlayersMap.addControl(this.modifyArea);
			this.modifyArea.mode = OpenLayers.Control.ModifyFeature.RESHAPE;

		}

		// calculates the tag cloud
		// manages hover selection of point objects
		var hoverSelect = function(event) {
			var object = event.feature;
			if (object.geometry instanceof OpenLayers.Geometry.Point) {
				if ( typeof map.placenameTags != 'undefined') {
					map.placenameTags.remove();
				}
				var circle = event.feature.parent;
				if ( circle instanceof CircleObject) {
					circle.placenameTags = new PlacenameTags(circle, map);
					map.placenameTags = circle.placenameTags;
				} else {
					return;
					/*
					 event.feature.style.fillOpacity = 0.2;
					 event.feature.style.strokeOpacity = 1;
					 map.objectLayer.drawFeature(event.feature);
					 circle.placenameTags = new PackPlacenameTags(circle,map);
					 */
				}
				circle.placenameTags.calculate();
				map.mapCircleHighlight(object.parent, false);
				if ( typeof map.featureInfo != 'undefined') {
					map.featureInfo.deactivate();
				}
			} else {
				map.dragControl.checkStatus();
			}
		};
		var hoverUnselect = function(event) {
			var object = event.feature;
			if (object.geometry instanceof OpenLayers.Geometry.Point) {
				var circle = event.feature.parent;
				if (!( circle instanceof CircleObject )) {
					return;
					/*
					 event.feature.style.fillOpacity = 0;
					 event.feature.style.strokeOpacity = 0;
					 map.objectLayer.drawFeature(event.feature);
					 */
				}
				circle.placenameTags.remove();
				map.mapCircleHighlight(object.parent, true);
				if ( typeof map.featureInfo != 'undefined') {
					map.featureInfo.activate();
				}
			} else {
				map.dragControl.deactivate();
			}
		};
		var highlightCtrl = new OpenLayers.Control.SelectFeature(this.objectLayer, {
			hover : true,
			highlightOnly : true,
			renderIntent : "temporary",
			eventListeners : {
				featurehighlighted : hoverSelect,
				featureunhighlighted : hoverUnselect
			}
		});
		this.openlayersMap.addControl(highlightCtrl);
		highlightCtrl.activate();

		this.selectFeature = new OpenLayers.Control.SelectFeature(this.objectLayer);

		document.onkeydown = function(e) {
			if (e.ctrlKey) {
				map.ctrlKey = true;
			}
		}
		document.onkeyup = function(e) {
			map.ctrlKey = false;
		}
		// manages click selection of point objects
		var onFeatureSelect = function(event, evt) {
			if (!(event.feature.geometry instanceof OpenLayers.Geometry.Point)) {
				return;
			}
			var circle = event.feature.parent;
			if (map.options.multiSelection && map.ctrlKey) {
				if (map.popup) {
					map.popup.reset();
					map.selectedGlyph = false;
				}
				circle.toggleSelection();
				map.mapSelection();
				return;
			}
			map.reset();
			circle.setSelection(true);
			map.objectLayer.drawFeature(circle.feature);
			if (map.options.popups) {
				if (map.popup) {
					map.popup.reset();
				}
				var lonlat = event.feature.geometry.getBounds().getCenterLonLat();
				var pixel = map.openlayersMap.getPixelFromLonLat(lonlat);
				map.selectedGlyph = {
					lon : lonlat.lon,
					lat : lonlat.lat
				};
				map.popup = new PlacenamePopup(map);
				map.popup.createPopup(pixel.x, pixel.y, circle.placenameTags.placeLabels);
				if (map.options.selectDefault) {
					circle.placenameTags.selectLabel();
				}
			}
		}
		this.objectLayer.events.on({
			"featureselected" : onFeatureSelect
		});

		this.openlayersMap.addControl(this.selectFeature);
		this.selectFeature.activate();

		if (this.zoomSlider) {
			this.zoomSlider.setMaxAndLevels(1000, this.openlayersMap.getNumZoomLevels());
			this.zoomSlider.setValue(this.getZoom());
		}
		
		Publisher.Subscribe('mapChanged', this, function(mapName) {
			this.client.setBaseLayerByName(mapName);
			this.client.gui.setMap();
		});

	},

	shift : function(shiftX, shiftY) {
		this.openlayersMap.pan(shiftX, shiftY);
	},

	addBaseLayers : function(layers) {
		if ( layers instanceof Array) {
			for (var i in layers ) {
				var layer;
				if (layers[i].type === "XYZ"){
			        layer = new OpenLayers.Layer.XYZ(
			        			layers[i].name,
				                [
				                 	layers[i].url
				                ], 
				                {
					                sphericalMercator: true,
					                transitionEffect: "resize",
					                buffer: 1,
					                numZoomLevels: 12,
					                transparent : true,
					                attribution: layers[i].attribution
				                }, 
								{
									isBaseLayer : true
								}
			            );
				} else {
					layer = new OpenLayers.Layer.WMS(
							layers[i].name, layers[i].url, 
							{
								projection : "EPSG:4326",
								layers : layers[i].layer,
								transparent : "true",
								format : "image/png"
							}, 
							{
				                attribution: layers[i].attribution,
								isBaseLayer : true
							}
					);
				}
				this.baseLayers.push(layer);
				this.openlayersMap.addLayers([layer]);
			}
		}
		this.gui.setMapsDropdown();
	},

	/**
	 * set online available maps for Google, Bing and OSM
	 */
	setBaseLayers : function() {
		this.baseLayers = [];
		if (this.options.googleMaps) {
			// see http://openlayers.org/blog/2010/07/10/google-maps-v3-for-openlayers/ for information
			var gphy = new OpenLayers.Layer.Google("Google Physical", {
				type : google.maps.MapTypeId.TERRAIN,
				minZoomLevel : 1,
				maxZoomLevel : 19
			});
			var gmap = new OpenLayers.Layer.Google("Google Streets", {
				minZoomLevel : 1,
				maxZoomLevel : 19
			});
			var ghyb = new OpenLayers.Layer.Google("Google Hybrid", {
				type : google.maps.MapTypeId.HYBRID,
				minZoomLevel : 1,
				maxZoomLevel : 19
			});
			var gsat = new OpenLayers.Layer.Google("Google Satellite", {
				type : google.maps.MapTypeId.SATELLITE,
				minZoomLevel : 1,
				maxZoomLevel : 19
			});
			this.baseLayers.push(gphy);
			this.baseLayers.push(gmap);
			this.baseLayers.push(ghyb);
			this.baseLayers.push(gsat);
		}
		if (this.options.bingMaps) {
			// see http://openlayers.org/blog/2010/12/18/bing-tiles-for-openlayers/ for information
			var apiKey = this.options.bingApiKey;
			var road = new OpenLayers.Layer.Bing({
				name : "Road",
				key : apiKey,
				type : "Road"
			});
			var hybrid = new OpenLayers.Layer.Bing({
				name : "Hybrid",
				key : apiKey,
				type : "AerialWithLabels"
			});
			var aerial = new OpenLayers.Layer.Bing({
				name : "Aerial",
				key : apiKey,
				type : "Aerial"
			});
			this.baseLayers.push(road);
			this.baseLayers.push(hybrid);
			this.baseLayers.push(aerial);
		}
		if (this.options.osmMaps) {
			this.baseLayers.push(new OpenLayers.Layer.OSM('Open Street Map', '', {
				sphericalMercator : true,
				zoomOffset : 1,
				resolutions : this.resolutions
			}));
		}
		if (this.options.osmMapsMapQuest) {
			this.baseLayers.push(new OpenLayers.Layer.OSM('Open Street Map (MapQuest)', 
				["http://otile1.mqcdn.com/tiles/1.0.0/map/${z}/${x}/${y}.png",
				 "http://otile2.mqcdn.com/tiles/1.0.0/map/${z}/${x}/${y}.png",
				 "http://otile3.mqcdn.com/tiles/1.0.0/map/${z}/${x}/${y}.png",
				 "http://otile4.mqcdn.com/tiles/1.0.0/map/${z}/${x}/${y}.png"], 
	            {
					sphericalMercator : true,
					zoomOffset : 1,
					resolutions : this.resolutions
	            }
			));
		}
		for (var i = 0; i < this.baseLayers.length; i++) {
			this.openlayersMap.addLayers([this.baseLayers[i]]);
		}
		if (this.options.alternativeMap) {
			if (!(this.options.alternativeMap instanceof Array))
				this.options.alternativeMap = [this.options.alternativeMap];
			this.addBaseLayers(this.options.alternativeMap);
		}
		this.setBaseLayerByName(this.options.baseLayer);
	},

	setBaseLayerByName : function(name){
		for (var i = 0; i < this.baseLayers.length; i++) {
			if (this.baseLayers[i].name == name) {
				this.setMap(i);
			}
		}
	},

	getBaseLayerName : function() {
		return this.openlayersMap.baseLayer.name;
	},

	setOverlays : function(layers) {
		var map = this;
		for (var i in this.wmsOverlays ) {
			this.openlayersMap.removeLayer(this.wmsOverlays[i]);
		}
		this.wmsOverlays = [];
		var featureInfoLayers = [];
		if ( layers instanceof Array) {
			for (var i in layers ) {
				var layer = new OpenLayers.Layer.WMS(layers[i].name, layers[i].url, {
					projection : "EPSG:4326",
					layers : layers[i].layer,
					transparent : "true",
					format : "image/png"
				}, {
					isBaseLayer : false,
					visibility : map.options.overlayVisibility
				});
				this.wmsOverlays.push(layer);
				if (layers[i].featureInfo) {
					featureInfoLayers.push(layer);
				}
			}
			this.openlayersMap.addLayers(this.wmsOverlays);
		}
		if (this.wmsOverlays.length > 0 && map.options.overlayVisibility) {
			var map = this;
			if ( typeof this.featureInfo != 'undefined') {
				this.featureInfo.deactivate();
				this.openlayersMap.removeControl(this.featureInfo);
			}
			this.featureInfo = new OpenLayers.Control.WMSGetFeatureInfo({
				url : '/geoserver/wms',
				layers : featureInfoLayers,
				eventListeners : {
					getfeatureinfo : function(event) {
						if (event.text == '') {
							return;
						}
						var lonlat = map.openlayersMap.getLonLatFromPixel(new OpenLayers.Pixel(event.xy.x, event.xy.y));
						map.selectedGlyph = {
							lon : lonlat.lon,
							lat : lonlat.lat
						};
						if ( typeof map.popup != 'undefined') {
							map.popup.reset();
						}
						map.popup = new MapPopup(map);
						map.popup.initialize(event.xy.x, event.xy.y);
						map.popup.setContent(event.text);
					}
				}
			});
			this.openlayersMap.addControl(this.featureInfo);
			this.featureInfo.activate();
			this.activateCountrySelector(this.wmsOverlays[this.wmsOverlays.length - 1]);
		} else {
			this.deactivateCountrySelector();
			if (this.openlayersMap.baseLayer instanceof OpenLayers.Layer.WMS) {
				this.activateCountrySelector(this.openlayersMap.baseLayer);
			}
		}
	},

	addBaseLayer : function(layer) {
		this.baseLayers.push(layer);
		this.openlayersMap.addLayers([layer]);
		for (var i in this.baseLayers ) {
			if (this.baseLayers[i].name == this.options.baseLayer) {
				this.setMap(i);
			}
		}
	},

	/**
	 * draws the object layer.
	 * @param {boolean} zoom if there was a zoom; if not, the new boundary of the map is calculated
	 */
	drawObjectLayer : function(zoom) {
		if ( typeof this.placenameTags != 'undefined') {
			this.placenameTags.remove();
		}
		var points = this.mds.getAllObjects();
		if (points == null) {
			return;
		}
		this.objectLayer.removeAllFeatures();

		if (zoom) {
			var minLat, maxLat, minLon, maxLon;
			var pointsHighestZoom = points[points.length - 1];
			for (var i = 0; i < pointsHighestZoom.length; i++) {
				for (var j = 0; j < pointsHighestZoom[i].length; j++) {
					var point = pointsHighestZoom[i][j];
					if (minLon == null || point.originX < minLon) {
						minLon = point.originX;
					}
					if (maxLon == null || point.originX > maxLon) {
						maxLon = point.originX;
					}
					if (minLat == null || point.originY < minLat) {
						minLat = point.originY;
					}
					if (maxLat == null || point.originY > maxLat) {
						maxLat = point.originY;
					}
				}
			}
			if (minLon == maxLon && minLat == maxLat) {
				this.openlayersMap.setCenter(new OpenLayers.LonLat(minLon, minLat));
			} else {
				var gapX = 0.1 * (maxLon - minLon );
				var gapY1 = 0.1 * (maxLat - minLat );
				var gapY2 = (this.gui.headerHeight / this.gui.mapWindow.offsetHeight + 0.1 ) * (maxLat - minLat );
				this.openlayersMap.zoomToExtent(new OpenLayers.Bounds(minLon - gapX, minLat - gapY1, maxLon + gapX, maxLat + gapY2));
				this.openlayersMap.zoomTo(Math.floor(this.getZoom()));
			}
			if (this.zoomSlider) {
				this.zoomSlider.setValue(this.getZoom());
			}
		}
		var displayPoints = this.mds.getObjectsByZoom();
		var resolution = this.openlayersMap.getResolution();
		for (var i = 0; i < displayPoints.length; i++) {
			for (var j = 0; j < displayPoints[i].length; j++) {
				var p = displayPoints[i][j];
				var x = p.originX + resolution * p.shiftX;
				var y = p.originY + resolution * p.shiftY;
				p.feature.geometry.x = x;
				p.feature.geometry.y = y;
				p.olFeature.geometry.x = x;
				p.olFeature.geometry.y = y;
				p.feature.style.graphicZIndex = this.zIndices[i];
				p.olFeature.style.graphicZIndex = this.zIndices[i] + 1;
				this.objectLayer.addFeatures([p.feature]);
				this.objectLayer.addFeatures([p.olFeature]);
			}
		}
		var zoomLevel = this.getZoom();
		/*
		 for (var i = 0; i < this.bins[zoomLevel].length; i++) {
		 var p = this.bins[zoomLevel][i];
		 p.feature.style.graphicZIndex = 0;
		 this.objectLayer.addFeatures([p.feature]);
		 }
		 */

		var dist = function(p1, p2) {
			return Math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
		}

		this.highlightChanged(this.selection.getObjects(this.core));

	},

	riseLayer : function(id) {
		this.lastId = id;
		if ( typeof id == 'undefined') {
			id = this.lastId || 0;
		}
		this.zIndices[id] = this.layerZIndex;
		this.layerZIndex += 2;
		this.drawObjectLayer(false);
		for( var i=0; i<this.polygons.length; i++ ){
			this.objectLayer.addFeatures([this.polygons[i]]);
		}
	},

	/**
	 * initializes the object layer.
	 * all point representations for all zoom levels are calculated and initialized
	 * @param {MapObject[][]} mapObjects an array of map objects from different (1-4) sets
	 */
	initWidget : function(datasets, zoom) {

		this.clearMap();

		this.datasets = datasets;
		var mapObjects = [];
		for (var i = 0; i < datasets.length; i++) {
			mapObjects.push(datasets[i].objects);
		}
		if (mapObjects.length > 4) {
			this.options.circlePackings = false;
		} else {
			this.options.circlePackings = this.formerCP;
		}

		if ( typeof mapObjects == 'undefined') {
			return;
		}

		this.count = 0;
		this.objectCount = 0;
		for (var i = 0; i < mapObjects.length; i++) {
			var c = 0;
			for (var j = 0; j < mapObjects[i].length; j++) {
				if (mapObjects[i][j].isGeospatial) {
					c += mapObjects[i][j].weight;
					this.objectCount++;
				}
			}
			this.count += c;
			this.zIndices.push(this.layerZIndex);
			this.layerZIndex += 2;
		}

		this.mds.initialize(mapObjects);
		var points = this.mds.getAllObjects();
		if (points == null) {
			return;
		}

		var getArea = function(radius) {
			return Math.PI * radius * radius;
		}
		for (var i = 0; i < points.length; i++) {
			var area = 0;
			var maxRadius = 0;
			for (var j = 0; j < points[i].length; j++) {
				for (var k = 0; k < points[i][j].length; k++) {
					if (points[i][j][k].radius > maxRadius) {
						maxRadius = points[i][j][k].radius;
						area = getArea(maxRadius);
					}
				}
			}
			var minArea = getArea(this.options.minimumRadius);
			var areaDiff = area - minArea;
			for (var j = 0; j < points[i].length; j++) {
				for (var k = 0; k < points[i][j].length; k++) {
					var point = points[i][j][k];
					var c, shape, rotation, multiplier = 1;
					if( this.options.useGraphics ){
						var graphic = this.config.getGraphic(point.search);
						c = graphic.color;
						shape = graphic.shape;
						rotation = graphic.rotation;
						if( shape == 'square' ){
							multiplier = 0.75;
						}
					}
					else {
						c = GeoTemConfig.getAverageDatasetColor(point.search,point.elements);
						shape = 'circle';
						rotation = 0;
					}
					var opacity;
					if (this.options.circleOpacity == 'balloon') {
						var min = this.options.minTransparency;
						var max = this.options.maxTransparency;
						opacity = min + Math.abs(min - max) * (1 - (getArea(point.radius) - minArea) / areaDiff);
					}
					else {
						opacity = this.options.circleOpacity;
					}
					var col = false, ols = 0;
					if( this.options.circleOutline ){
						col = true;
						ols = this.options.circleOutline;
					}
					var style = {
						graphicName: shape,
						rotation: rotation,
						fillColor : 'rgb(' + c.r0 + ',' + c.g0 + ',' + c.b0 + ')',
						fillOpacity : opacity,
						strokeWidth : ols,
						strokeColor : 'rgb(' + c.r1 + ',' + c.g1 + ',' + c.b1 + ')',
						stroke : col,
						pointRadius : point.radius * multiplier,
						cursor : "pointer"
					};
					var pointGeometry = new OpenLayers.Geometry.Point(point.originX, point.originY, null);
					var feature = new OpenLayers.Feature.Vector(pointGeometry);
					feature.style = style;
					feature.parent = point;
					point.setFeature(feature);
					var olStyle = {
						graphicName: shape,
						rotation: rotation,
						fillColor : 'rgb(' + c.r1 + ',' + c.g1 + ',' + c.b1 + ')',
						fillOpacity : opacity,
						stroke : false,
						pointRadius : 0,
						cursor : "pointer"
					};
					var olPointGeometry = new OpenLayers.Geometry.Point(point.originX, point.originY, null);
					var olFeature = new OpenLayers.Feature.Vector(olPointGeometry);
					olFeature.style = olStyle;
					olFeature.parent = point;
					point.setOlFeature(olFeature);
				}
			}
		}

		/*
		 this.bins = this.mds.getAllBins();
		 for (var i = 0; i < this.bins.length; i++) {
		 for (var j = 0; j < this.bins[i].length; j++) {
		 var bin = this.bins[i][j];
		 var style = {
		 fillColor : 'rgb(140,140,140)',
		 fillOpacity : 0,
		 strokeWidth : 2,
		 strokeOpacity : 0,
		 strokeColor : 'rgb(140,140,140)',
		 //					stroke: false,
		 pointRadius : bin.radius,
		 cursor : "pointer"
		 };
		 var pointGeometry = new OpenLayers.Geometry.Point(bin.x, bin.y, null);
		 var feature = new OpenLayers.Feature.Vector(pointGeometry);
		 feature.style = style;
		 feature.parent = bin;
		 bin.feature = feature;
		 }
		 }
		 */

		this.gui.updateLegend(datasets);

		if ( typeof zoom == "undefined") {
			this.drawObjectLayer(true);
		} else {
			this.drawObjectLayer(zoom);
		}
		this.gui.updateSpaceQuantity(this.count);

	},

	/**
	 * resets the map by destroying all additional elements except the point objects, which are replaced
	 */
	reset : function() {
		if ( typeof this.placenameTags != 'undefined') {
			this.placenameTags.remove();
		}
		this.objectLayer.removeFeatures(this.polygons);
		this.polygons = [];
		this.objectLayer.removeFeatures(this.connections);
		this.connections = [];
		this.selectFeature.unselectAll();
		this.selectedGlyph = false;
		if (this.dragControl.activated) {
			this.dragControl.deactivate();
		}
		if (this.popup) {
			this.popup.reset();
		}
		this.filterBar.reset(false);
		var points = this.mds.getObjectsByZoom();
		if (points == null) {
			return;
		}
		for (var i = 0; i < points.length; i++) {
			for (var j = 0; j < points[i].length; j++) {
				points[i][j].setSelection(false);
			}
		}
	},

	/**
	 * resets the map by destroying all elements
	 */
	clearMap : function() {
		this.reset();
		this.selection = new Selection();
		this.zIndices = [];
		this.layerZIndex = 1;
		this.objectLayer.destroyFeatures();
	},

	/**
	 * updates the proportional selection status of a point object
	 * @param {PointObject} point the point to update
	 * @param {OpenLayers.Geometry.Polygon} polygon the actual displayed map polygon
	 */
	updatePoint : function(point, polygon) {
		var olRadius = this.mds.binning.getRadius(point.overlay);
		if( this.options.useGraphics ){
			var graphic = this.config.getGraphic(point.search);
			if( graphic.shape == 'square' ){
				olRadius *= 0.75;
			}
		}
		point.olFeature.style.pointRadius = olRadius;
		var c = GeoTemConfig.getAverageDatasetColor(point.search, point.overlayElements);
		point.olFeature.style.fillColor = 'rgb(' + c.r1 + ',' + c.g1 + ',' + c.b1 + ')';
		if (polygon.containsPoint(point.feature.geometry)) {
			this.objectLayer.drawFeature(point.olFeature);
		}
	},

	/**
	 * updates the the object layer of the map after selections had been executed in timeplot or table or zoom level has changed
	 */
	highlightChanged : function(mapObjects) {
		var hideEmptyCircles = false;

		if (this.config.options.hideUnselected){
			var overallCnt = 0;
			for (var i in mapObjects){
				overallCnt += mapObjects[i].length;
			}
			if (overallCnt > 0){
				hideEmptyCircles = true;
			}
		}
		
		if( !GeoTemConfig.highlightEvents ){
			return;
		}
		this.mds.clearOverlay();
		if (this.selection.valid()) {
			this.mds.setOverlay(GeoTemConfig.mergeObjects(mapObjects, this.selection.getObjects()));
		} else {
			this.mds.setOverlay(mapObjects);
		}
		var points = this.mds.getObjectsByZoom();
		var polygon = this.openlayersMap.getExtent().toGeometry();
		for (var i in points ) {
			for (var j in points[i] ) {
				var point = points[i][j];
				
				if (hideEmptyCircles){
					point.feature.style.display = 'none';
				} else {
					point.feature.style.display = '';
				} 
					
				this.updatePoint(points[i][j], polygon);
			}
		}
		this.displayConnections();
		this.objectLayer.redraw();
	},

	selectionChanged : function(selection) {
		if( !GeoTemConfig.selectionEvents ){
			return;
		}
		this.reset();
		this.selection = selection;
		this.highlightChanged(selection.objects);
	},

	inPolygon : function(point) {
		for (var i = 0; i < this.polygons.length; i++) {
			var polygon = this.polygons[i].geometry;
			for (var j = 0; j < polygon.components.length; j++) {
				if (polygon.components[j].containsPoint(point.feature.geometry)) {
					return true;
				}
			}
		}
		return false;
	},

	mapSelection : function() {
		var selectedObjects = [];
		for (var i = 0; i < this.mds.size(); i++) {
			selectedObjects.push([]);
		}
		var circles = this.mds.getObjectsByZoom();
		for (var i = 0; i < circles.length; i++) {

			for (var j = 0; j < circles[i].length; j++) {
				var c = circles[i][j];
				if (c.selected) {
					selectedObjects[i] = selectedObjects[i].concat(c.elements);
				}
			}
		}
		this.selection = new Selection(selectedObjects, this);
		this.highlightChanged(selectedObjects);
		this.core.triggerSelection(this.selection);
		this.filterBar.reset(true);
	},

	deselection : function() {
		this.reset();
		this.selection = new Selection();
		this.highlightChanged([]);
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
		for (var i = 0; i < this.mds.size(); i++) {
			selectedObjects.push([]);
		}
		var circles = this.mds.getObjectsByZoom();
		for (var i = 0; i < circles.length; i++) {
			for (var j = 0; j < circles[i].length; j++) {
				var c = circles[i][j];
				if (!c.selected) {
					selectedObjects[i] = selectedObjects[i].concat(c.elements);
				}
			}
		}
		this.selection = new Selection(selectedObjects, this);
		this.filtering();
	},

	mapCircleHighlight : function(circle, undo) {
		if (this.polygons.length > 0 && this.inPolygon(circle)) {
			return;
		}
		var mapObjects = [];
		for (var i = 0; i < this.mds.size(); i++) {
			mapObjects.push([]);
		}
		if (!undo && !circle.selected) {
			mapObjects[circle.search] = circle.elements;
		}
		this.objectLayer.drawFeature(circle.feature);
		this.core.triggerHighlight(mapObjects);
	},

	mapLabelSelection : function(label) {
		var selectedObjects = [];
		for (var i = 0; i < this.mds.size(); i++) {
			selectedObjects.push([]);
		}
		selectedObjects[label.index] = label.elements;
		this.selection = new Selection(selectedObjects, this);
		this.highlightChanged(selectedObjects);
		this.core.triggerSelection(this.selection);
		this.filterBar.reset(true);
	},
	
	triggerMapChanged : function(mapName) {
		Publisher.Publish('mapChanged', mapName, this);
	},

	/**
	 * displays connections between data objects
	 */
	displayConnections : function() {
		return;
		if ( typeof this.connection != 'undefined') {
			this.objectLayer.removeFeatures(this.connections);
			this.connections = [];
		}
		if (this.options.connections) {
			var points = this.mds.getObjectsByZoom();
			for (var i in points ) {
				for (var j in points[i] ) {

				}
			}

			var slices = this.core.timeplot.getSlices();
			for (var i = 0; i < slices.length; i++) {
				for (var j = 0; j < slices[i].stacks.length; j++) {
					var e = slices[i].stacks[j].elements;
					if (e.length == 0) {
						continue;
					}
					var points = [];
					for (var k = 0; k < e.length; k++) {
						var point = this.mds.getCircle(j, e[k].index).feature.geometry;
						if (arrayIndex(points, point) == -1) {
							points.push(point);
						}
					}
					var matrix = new AdjMatrix(points.length);
					for (var k = 0; k < points.length - 1; k++) {
						for (var l = k + 1; l < points.length; l++) {
							matrix.setEdge(k, l, dist(points[k], points[l]));
						}
					}
					var tree = Prim(matrix);
					var lines = [];
					for (var z = 0; z < tree.length; z++) {
						lines.push(new OpenLayers.Geometry.LineString(new Array(points[tree[z].v1], points[tree[z].v2])));
					}
					this.connections[j].push({
						first : this.mds.getCircle(j, e[0].index).feature.geometry,
						last : this.mds.getCircle(j, e[e.length - 1].index).feature.geometry,
						lines : lines,
						time : slices[i].date
					});
				}
			}
			var ltm = this.core.timeplot.leftFlagTime;
			var rtm = this.core.timeplot.rightFlagTime;
			if (ltm == undefined || ltm == null) {
				return;
			} else {
				ltm = ltm.getTime();
				rtm = rtm.getTime();
			}
			//        this.connectionLayer.destroyFeatures();
			if (thisConnections) {
				for (var i = 0; i < this.connections.length; i++) {
					var c = GeoTemConfig.colors[i];
					var style = {
						strokeColor : 'rgb(' + c.r1 + ',' + c.g1 + ',' + c.b1 + ')',
						strokeOpacity : 0.5,
						strokeWidth : 3
					};
					var pointsToConnect = [];
					var last = undefined;
					for (var j = 0; j < this.connections[i].length; j++) {
						var c = this.connections[i][j];
						var ct = c.time.getTime();
						if (ct >= ltm && ct <= rtm) {
							if (last != undefined) {
								var line = new OpenLayers.Geometry.LineString(new Array(last, c.first));
								this.connectionLayer.addFeatures([new OpenLayers.Feature.Vector(line, null, style)]);
							}
							for (var k = 0; k < c.lines.length; k++) {
								this.connectionLayer.addFeatures([new OpenLayers.Feature.Vector(c.lines[k], null, style)]);
							}
							last = c.last;
						}
					}
				}
				//            this.connectionLayer.redraw();
			}
		}
	},

	/**
	 * performs a zoom on the map
	 * @param {int} delta the change of zoom levels
	 */
	zoom : function(delta) {
		var zoom = this.getZoom() + delta;
		if (this.openlayersMap.baseLayer instanceof OpenLayers.Layer.WMS) {
			this.openlayersMap.zoomTo(zoom);
		} else {
			this.openlayersMap.zoomTo(Math.round(zoom));
			if (this.zoomSlider) {
				this.zoomSlider.setValue(this.getZoom());
			}
		}
		return true;
	},

	deactivateCountrySelector : function() {
		this.openlayersMap.removeControl(this.selectCountry);
		this.selectCountry = undefined;
	},

	activateCountrySelector : function(layer) {
		var map = this;
		if (this.options.countrySelect && this.options.mapSelectionTools) {
			this.selectCountry = new OpenLayers.Control.GetFeature({
				protocol : OpenLayers.Protocol.WFS.fromWMSLayer(layer),
				click : true
			});
			this.selectCountry.events.register("featureselected", this, function(e) {
				map.snapper();
				map.drawnPolygonHandler(e.feature.geometry);
			});
			this.openlayersMap.addControl(this.selectCountry);
			this.countrySelectionControl.enable();
		}
	},

	setMap : function(index) {
		this.baselayerIndex = index;
		if (this.selectCountry) {
			//			if( this.wmsOverlays.length == 0 ){
			this.deactivateCountrySelector();
			//			}
		}
		if (this.baseLayers[index] instanceof OpenLayers.Layer.WMS) {
			//			if( this.wmsOverlays.length == 0 ){
			this.activateCountrySelector(this.baseLayers[index]);
			//			}
		} else {
			if (this.countrySelectionControl) {
				this.countrySelectionControl.disable();
			}
		}
		this.openlayersMap.zoomTo(Math.floor(this.getZoom()));
		this.openlayersMap.setBaseLayer(this.baseLayers[index]);
		if (this.baseLayers[index].name == 'Open Street Map') {
			this.gui.osmLink.style.visibility = 'visible';
		} else {
			this.gui.osmLink.style.visibility = 'hidden';
		}
		if (this.baseLayers[index].name == 'Open Street Map (MapQuest)') {
			this.gui.osmMapQuestLink.style.visibility = 'visible';
		} else {
			this.gui.osmMapQuestLink.style.visibility = 'hidden';
		}
		this.triggerMapChanged(this.baseLayers[index].name);
	},

	//vhz added title to buttons
	initSelectorTools : function() {
		var map = this;
		this.mapControls = [];

		if (this.options.squareSelect) {
			var button = document.createElement("div");
			$(button).addClass('mapControl');
			var activate = function() {
				map.drawSquare.activate();
			}
			var deactivate = function() {
				map.drawSquare.deactivate();
			}
			this.mapControls.push(new MapControl(this, button, 'square', activate, deactivate));
		}
		if (this.options.circleSelect) {
			var button = document.createElement("div");
			$(button).addClass('mapControl');
			var activate = function() {
				map.drawCircle.activate();
			}
			var deactivate = function() {
				map.drawCircle.deactivate();
			}
			this.mapControls.push(new MapControl(this, button, 'circle', activate, deactivate));
		}
		if (this.options.polygonSelect) {
			var button = document.createElement("div");
			$(button).addClass('mapControl');
			var activate = function() {
				map.drawPolygon.activate();
			}
			var deactivate = function() {
				map.drawPolygon.deactivate();
			}
			this.mapControls.push(new MapControl(this, button, 'polygon', activate, deactivate));
		}
		if (this.options.countrySelect) {
			var button = document.createElement("div");
			$(button).addClass('mapControl');
			var activate = function() {
				map.selectCountry.activate();
				map.dragControl.disable();
			}
			var deactivate = function() {
				map.selectCountry.deactivate();
				map.dragControl.enable();
			}
			this.countrySelectionControl = new MapControl(this, button, 'country', activate, deactivate);
			this.mapControls.push(this.countrySelectionControl);
			/*
			 if( !(this.openlayersMap.baseLayer instanceof OpenLayers.Layer.WMS) ){
			 this.countrySelectionControl.disable();
			 }
			 */
		}
		return this.mapControls;
	},

	getZoom : function() {
    	//calculate zoom from active resolution
        var resolution = this.openlayersMap.getResolution();
        var zoom = this.resolutions.indexOf(resolution);
        if (zoom == -1){
            //fractional zoom
            for (zoom = 0; zoom < this.resolutions.length; zoom++){
                if (resolution>=this.resolutions[zoom]){
                    break;
                }
            }
            if (zoom == this.resolutions.length){
                zoom--;
            }
        }
        return(zoom);
	},

	setMarker : function(lon, lat) {
		var p = new OpenLayers.Geometry.Point(lon, lat, null);
		p.transform(this.openlayersMap.displayProjection, this.openlayersMap.projection);
		this.openlayersMap.setCenter(new OpenLayers.LonLat(p.x, p.y));
		var size = new OpenLayers.Size(22, 33);
		var offset = new OpenLayers.Pixel(-(size.w / 2), -size.h);
		var icon = new OpenLayers.Icon(GeoTemConfig.path + 'marker.png', size, offset);
		var marker = new OpenLayers.Marker(new OpenLayers.LonLat(p.x, p.y), icon);
		marker.setOpacity(0.9);
		this.markerLayer.setZIndex(parseInt(this.objectLayer.getZIndex()) + 1);
		this.markerLayer.addMarker(marker);
		// find nearest neighbor
		var nearestNeighbor;
		var points = this.mds.getAllObjects();
		if (points == null) {
			return;
		}
		var dist = function(p1, p2) {
			return Math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
		}
		var zoomLevels = this.openlayersMap.getNumZoomLevels();
		var pointSet = points[zoomLevels - 1];
		var closestDistance = undefined;
		var closestPoint;
		for (var i = 0; i < pointSet.length; i++) {
			for (var j = 0; j < pointSet[i].length; j++) {
				var point = pointSet[i][j].feature.geometry;
				var d = dist(point, p);
				if (!closestDistance || d < closestDistance) {
					closestDistance = d;
					closestPoint = point;
				}
			}
		}
		// find minimal zoom level
		var gap = 0;
		var x_s = this.gui.mapWindow.offsetWidth / 2 - gap;
		var y_s = this.gui.mapWindow.offsetHeight / 2 - gap;
		if (typeof closestPoint !== "undefined"){
			var xDist = Math.abs(p.x - closestPoint.x);
			var yDist = Math.abs(p.y - closestPoint.y);
			for (var i = 0; i < zoomLevels; i++) {
				var resolution = this.openlayersMap.getResolutionForZoom(zoomLevels - i - 1);
				if (xDist / resolution < x_s && yDist / resolution < y_s) {
					this.openlayersMap.zoomTo(zoomLevels - i - 1);
					if (this.zoomSlider) {
						this.zoomSlider.setValue(this.getZoom());
					}
					this.drawObjectLayer(false);
					break;
				}
			}
		} else {
			//if there are no points on the map, zoom to max 
			this.openlayersMap.zoomTo(0);
			if (this.zoomSlider) {
				this.zoomSlider.setValue(this.getZoom());
			}
			this.drawObjectLayer(false);
		}
	},

	removeMarker : function() {
		this.markerLayer.removeMarker(this.markerLayer.markers[0]);
	},

	getLevelOfDetail : function() {
		var zoom = Math.floor(this.getZoom());
		if (zoom <= 1) {
			return 0;
		} else if (zoom <= 3) {
			return 1;
		} else if (zoom <= 8) {
			return 2;
		} else {
			return 3;
		}
	}
}
