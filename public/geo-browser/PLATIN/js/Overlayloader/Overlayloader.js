/*
* Overlayloader.js
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
 * @class Overlayloader
 * Implementation for a Overlayloader UI
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {HTML object} parent div to append the Overlayloader
 */
function Overlayloader(parent) {

	this.overlayLoader = this;
	
	this.parent = parent;
	this.options = parent.options;
	this.attachedMapWidgets = parent.attachedMapWidgets;

	this.overlays = [];

	this.initialize();
}

Overlayloader.prototype = {

	show : function() {
		this.overlayloaderDiv.style.display = "block";
	},

	hide : function() {
		this.overlayloaderDiv.style.display = "none";
	},

	initialize : function() {

		this.addKMLLoader();
		this.addKMZLoader();
		this.addArcGISWMSLoader();
		this.addXYZLoader();
		this.addRomanEmpireLoader();
		this.addMapsForFreeWaterLayer();
		this.addConfigLoader();
		
		// trigger change event on the select so 
		// that only the first loader div will be shown
		$(this.parent.gui.loaderTypeSelect).change();
	},
	
	distributeKML : function(kmlURL) {
		var newOverlay = new Object();
		newOverlay.name = kmlURL;
		newOverlay.layers = [];
		
		$(this.attachedMapWidgets).each(function(){
			var newLayer = new OpenLayers.Layer.Vector("KML", {
				projection: this.openlayersMap.displayProjection,
	            strategies: [new OpenLayers.Strategy.Fixed()],
	            protocol: new OpenLayers.Protocol.HTTP({
	                url: kmlURL,
	                format: new OpenLayers.Format.KML({
	                    extractStyles: true,
	                    extractAttributes: true
	                })
	            })
	        });
			
			newOverlay.layers.push({map:this.openlayersMap,layer:newLayer});

			this.openlayersMap.addLayer(newLayer);
		});
		
		this.overlays.push(newOverlay);
		this.parent.gui.refreshOverlayList();
	},
	
	distributeKMZ : function(kmzURL) {
		var newOverlay = new Object();
		newOverlay.name = kmzURL;
		newOverlay.layers = [];
		
		$(this.attachedMapWidgets).each(function(){
			var newLayer = new OpenLayers.Layer.Vector("KML", {
				projection: this.openlayersMap.displayProjection,
				strategies: [new OpenLayers.Strategy.Fixed()],
				format: OpenLayers.Format.KML,
				extractAttributes: true
			});
			
			newOverlay.layers.push({map:this.openlayersMap,layer:newLayer});
			
			var map = this.openlayersMap;
					
			GeoTemConfig.getKmz(kmzURL, function(kmlDoms){
				$(kmlDoms).each(function(){
					var kml = new OpenLayers.Format.KML().read(this);
					newLayer.addFeatures(kml);
					map.addLayer(newLayer);
				});
			});
		});
		
		this.overlays.push(newOverlay);
		this.parent.gui.refreshOverlayList();
	},
	
	distributeArcGISWMS : function(wmsURL, wmsLayer) {
		var newOverlay = new Object();
		newOverlay.name = wmsURL + " - " + wmsLayer;
		newOverlay.layers = [];
		
		var newLayer = new OpenLayers.Layer.WMS("ArcGIS WMS label", wmsURL, {
				layers: wmsLayer,
				format: "image/png",
				transparent: "true"
			}
	    	,{
                displayOutsideMaxExtent: true,
                isBaseLayer: false,
	    		projection : "EPSG:3857"
	    	}
		);

		newLayer.setIsBaseLayer(false);
		$(this.attachedMapWidgets).each(function(){
			this.openlayersMap.addLayer(newLayer);
			newOverlay.layers.push({map:this.openlayersMap,layer:newLayer});			
		});
		
		this.overlays.push(newOverlay);
		this.parent.gui.refreshOverlayList();
	},

	distributeXYZ : function(xyzURL,zoomOffset) {
		var newOverlay = new Object();
		newOverlay.name = xyzURL;
		newOverlay.layers = [];
		
        var newLayer = new OpenLayers.Layer.XYZ(
                "XYZ Layer",
                [
                  xyzURL
                ], {
                sphericalMercator: true,
                transitionEffect: "resize",
                buffer: 1,
                numZoomLevels: 12,
                transparent : true,
                isBaseLayer : false,
                zoomOffset:zoomOffset?zoomOffset:0
              }
            );

		newLayer.setIsBaseLayer(false);
		$(this.attachedMapWidgets).each(function(){
			this.openlayersMap.addLayer(newLayer);
			newOverlay.layers.push({map:this.openlayersMap,layer:newLayer});
		});
		
		this.overlays.push(newOverlay);
		this.parent.gui.refreshOverlayList();
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
			if (kmlURL.length == 0)
				return;
			if (typeof GeoTemConfig.proxy != 'undefined')
				kmlURL = GeoTemConfig.proxy + kmlURL;
			
			this.distributeKML(kmlURL);
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
			var kmzURL = $(this.kmzURL).val();
			if (kmzURL.length == 0)
				return;
			if (typeof GeoTemConfig.proxy != 'undefined')
				kmzURL = GeoTemConfig.proxy + kmzURL;
			
			this.distributeKMZ(kmzURL);
		},this));

		$(this.parent.gui.loaders).append(this.KMZLoaderTab);
	},
	
	addArcGISWMSLoader : function() {
		$(this.parent.gui.loaderTypeSelect).append("<option value='ArcGISWMSLoader'>ArcGIS WMS</option>");
		
		this.ArcGISWMSLoaderTab = document.createElement("div");
		$(this.ArcGISWMSLoaderTab).attr("id","ArcGISWMSLoader");
		
		$(this.ArcGISWMSLoaderTab).append("URL: ");
		
		this.wmsURL = document.createElement("input");
		$(this.wmsURL).attr("type","text");
		$(this.ArcGISWMSLoaderTab).append(this.wmsURL);
		
		$(this.ArcGISWMSLoaderTab).append("Layer: ");
		
		this.wmsLayer = document.createElement("input");
		$(this.wmsLayer).attr("type","text");
		$(this.ArcGISWMSLoaderTab).append(this.wmsLayer);
		
		this.loadArcGISWMSButton = document.createElement("button");
		$(this.loadArcGISWMSButton).text("load Layer");
		$(this.ArcGISWMSLoaderTab).append(this.loadArcGISWMSButton);

		$(this.loadArcGISWMSButton).click($.proxy(function(){
			var wmsURL = $(this.wmsURL).val();
			var wmsLayer = $(this.wmsLayer).val();
			if (wmsURL.length == 0)
				return;
			
			this.distributeArcGISWMS(wmsURL, wmsLayer);
		},this));

		$(this.parent.gui.loaders).append(this.ArcGISWMSLoaderTab);
	},
	
	addXYZLoader : function() {
		$(this.parent.gui.loaderTypeSelect).append("<option value='XYZLoader'>XYZ Layer</option>");
		
		this.XYZLoaderTab = document.createElement("div");
		$(this.XYZLoaderTab).attr("id","XYZLoader");
		
		$(this.XYZLoaderTab).append("URL (with x,y,z variables): ");
		
		this.xyzURL = document.createElement("input");
		$(this.xyzURL).attr("type","text");
		$(this.XYZLoaderTab).append(this.xyzURL);
		
		this.loadXYZButton = document.createElement("button");
		$(this.loadXYZButton).text("load Layer");
		$(this.XYZLoaderTab).append(this.loadXYZButton);

		$(this.loadXYZButton).click($.proxy(function(){
			var xyzURL = $(this.xyzURL).val();
			if (xyzURL.length == 0)
				return;
			
			this.distributeXYZ(xyzURL);
		},this));

		$(this.parent.gui.loaders).append(this.XYZLoaderTab);
	},
	
	addRomanEmpireLoader : function() {
		$(this.parent.gui.loaderTypeSelect).append("<option value='RomanEmpireLoader'>Roman Empire</option>");
		
		this.RomanEmpireLoaderTab = document.createElement("div");
		$(this.RomanEmpireLoaderTab).attr("id","RomanEmpireLoader");

		this.loadRomanEmpireButton = document.createElement("button");
		$(this.loadRomanEmpireButton).text("load Layer");
		$(this.RomanEmpireLoaderTab).append(this.loadRomanEmpireButton);

		$(this.loadRomanEmpireButton).click($.proxy(function(){
			this.distributeXYZ("http://pelagios.org/tilesets/imperium/${z}/${x}/${y}.png",1);
		},this));

		$(this.parent.gui.loaders).append(this.RomanEmpireLoaderTab);
	},
	
	addMapsForFreeWaterLayer : function() {
		$(this.parent.gui.loaderTypeSelect).append("<option value='MapsForFreeWaterLayerLoader'>Water Layer (Maps-For-Free)</option>");
		
		this.MapsForFreeWaterTab = document.createElement("div");
		$(this.MapsForFreeWaterTab).attr("id","MapsForFreeWaterLayerLoader");

		this.loadMapsForFreeWaterLayerButton = document.createElement("button");
		$(this.loadMapsForFreeWaterLayerButton).text("load Layer");
		$(this.MapsForFreeWaterTab).append(this.loadMapsForFreeWaterLayerButton);

		$(this.loadMapsForFreeWaterLayerButton).click($.proxy(function(){
			this.distributeXYZ("http://maps-for-free.com/layer/water/z${z}/row${y}/${z}_${x}-${y}.gif",1);
		},this));

		$(this.parent.gui.loaders).append(this.MapsForFreeWaterTab);
	},
	
	addConfigLoader : function() {
		if (	(this.parent.options.wms_overlays instanceof Array) &&
				(this.parent.options.wms_overlays.length > 0) ){
			var overlayloader = this;
			
			$(this.parent.gui.loaderTypeSelect).append("<option value='ConfigLoader'>Other WMS maps</option>");
			
			this.ConfigLoaderTab = document.createElement("div");
			$(this.ConfigLoaderTab).attr("id","ConfigLoader");

			this.ConfigMapSelect = document.createElement("select");
			$(this.parent.options.wms_overlays).each(function(){
				var name = this.name, server = this.server, layer = this.layer;
				$(overlayloader.ConfigMapSelect).append("<option layer='"+layer+"' server='"+server+"' >"+name+"</option>");
			});		

			$(this.ConfigLoaderTab).append(this.ConfigMapSelect);

			this.loadConfigMapButton = document.createElement("button");
			$(this.loadConfigMapButton).text("load Layer");
			$(this.ConfigLoaderTab).append(this.loadConfigMapButton);
			
			$(this.loadConfigMapButton).click($.proxy(function(){
				var server = $(this.ConfigMapSelect).find(":selected").attr("server");
				var layer = $(this.ConfigMapSelect).find(":selected").attr("layer");
				this.distributeArcGISWMS(server,layer);
			},this));

			$(this.parent.gui.loaders).append(this.ConfigLoaderTab);
		}
	}

};
