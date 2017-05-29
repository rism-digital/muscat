/*
* Loader.js
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
 * Script Loader for GeoTemCo (used for debugging purposes)
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */

var arrayIndex = function(array, obj) {
	return $.inArray(obj, array);
}
GeoTemCoLoader = {

	resolveUrlPrefix : function(file) {
		var sources = document.getElementsByTagName("script");
		for (var i = 0; i < sources.length; i++) {
			var index = sources[i].src.indexOf(file);
			if (index != -1) {
				return sources[i].src.substring(0, index);
			}
		}
	},

	load : function() {
		GeoTemCoLoader.startTime = new Date();
		GeoTemCoLoader.urlPrefix = GeoTemCoLoader.resolveUrlPrefix('js/Build/Loader/Loader.js');
		(new DynaJsLoader()).loadScripts([{
			url : GeoTemCoLoader.urlPrefix + 'js/Build/Loader/TimeplotLoader.js'
		}], GeoTemCoLoader.loadJquery);
	},

	loadJquery : function() {
		if (typeof jQuery == 'undefined') {
			(new DynaJsLoader()).loadScripts([{
				url : GeoTemCoLoader.urlPrefix + 'lib/jquery/jquery.min.js'
			},{
				url : GeoTemCoLoader.urlPrefix + 'lib/jquery/purl.min.js'
			},{
				url : GeoTemCoLoader.urlPrefix + 'lib/jquery/jquery.remember.js'
			},{
				url : GeoTemCoLoader.urlPrefix + 'lib/jquery/jquery-deparam.min.js'
			},],GeoTemCoLoader.loadFlot);
		}
		else {
			GeoTemCoLoader.loadFlot();
		}
	},
	
	loadFlot : function() {
		if (typeof $.plot == 'undefined') {
			(new DynaJsLoader()).loadScripts([{
				url : GeoTemCoLoader.urlPrefix + 'lib/flot/jquery.flot.js'
			},{
				url : GeoTemCoLoader.urlPrefix + 'lib/flot/jquery.flot.resize.js'
			},{
				url : GeoTemCoLoader.urlPrefix + 'lib/flot/jquery.flot.pie.js'
			},{
				url : GeoTemCoLoader.urlPrefix + 'lib/flot/jquery.flot.selection.js'
			},{
				url : GeoTemCoLoader.urlPrefix + 'lib/flot/jquery.flot.time.js'
			},{
				url : GeoTemCoLoader.urlPrefix + 'lib/flot/jquery.flot.tooltip.js'
			}],GeoTemCoLoader.loadMomentJS);
		}
		else {
			GeoTemCoLoader.loadMomentJS();
		}
	},
	
	loadMomentJS : function() {
		if (typeof moment == 'undefined') {
			(new DynaJsLoader()).loadScripts([{
				url : GeoTemCoLoader.urlPrefix + 'lib/momentjs/moment.js'
			}],GeoTemCoLoader.loadJSZip);
		}
		else {
			GeoTemCoLoader.loadJSZip();
		}
	},
	
	loadJSZip : function() {
		if (typeof JSZip == 'undefined') {
			var jsZipFiles = [{
				url : GeoTemCoLoader.urlPrefix + 'lib/jszip/jszip.min.js',
			}];
			
			(new DynaJsLoader()).loadScripts(jsZipFiles, GeoTemCoLoader.loaduCSV);
		}
		else {
			GeoTemCoLoader.loaduCSV();
		}
	},

	loaduCSV : function() {
		if (typeof CSV == 'undefined') {
			var jsZipFiles = [{
				url : GeoTemCoLoader.urlPrefix + 'lib/ucsv/ucsv-1.1.0-min.js',
			}];
			
			(new DynaJsLoader()).loadScripts(jsZipFiles, GeoTemCoLoader.loadSheetJS);
		}
		else {
			GeoTemCoLoader.loadSheetJS();
		}
	},

	loadSheetJS : function() {
		if (typeof XLSX == 'undefined') {
			var sheetJSFiles = [
			                    {url : GeoTemCoLoader.urlPrefix + 'lib/sheetjs/shim.js'},
								{url : GeoTemCoLoader.urlPrefix + 'lib/sheetjs/xls.min.js'},
								{url : GeoTemCoLoader.urlPrefix + 'lib/sheetjs/xlsx.js'},
			];
			
			(new DynaJsLoader()).loadScripts(sheetJSFiles, GeoTemCoLoader.loadJqueryUI);
		}
		else {
			GeoTemCoLoader.loadJqueryUI();
		}
	},

	loadJqueryUI : function() {
		if (typeof jQuery.ui == 'undefined') {
			var jsZipFiles = [{
				url : GeoTemCoLoader.urlPrefix + 'lib/jquery-ui/jquery-ui-1.10.3.custom.js'
			}];
			
			$('head').append( $('<link rel="stylesheet" type="text/css" />').attr('href', GeoTemCoLoader.urlPrefix + 'lib/jquery-ui/jquery-ui-1.10.3.custom.css') );
			
			(new DynaJsLoader()).loadScripts(jsZipFiles, GeoTemCoLoader.loadTimeplot);
		}
		else {
			GeoTemCoLoader.loadTimeplot();
		}
	},

	loadTimeplot : function() {
		var jsFiles = [{
			url : GeoTemCoLoader.urlPrefix + 'lib/SimileRemnants.js'
		}];
		
		(new DynaJsLoader()).loadScripts(jsFiles, GeoTemCoLoader.loadScripts);
	},

	loadScripts : function() {

		SimileAjax.includeCssFile(document, GeoTemCoLoader.urlPrefix + 'css/style.css');
		SimileAjax.includeCssFile(document, GeoTemCoLoader.urlPrefix + 'lib/openlayers/theme/default/style.css');

		(new DynaJsLoader()).loadScripts([{
			url : GeoTemCoLoader.urlPrefix + 'lib/slider/js/range.js'
		}]);
		(new DynaJsLoader()).loadScripts([{
			url : GeoTemCoLoader.urlPrefix + 'lib/slider/js/slider.js'
		}]);
		(new DynaJsLoader()).loadScripts([{
			url : GeoTemCoLoader.urlPrefix + 'lib/slider/js/timer.js'
		}]);
		// SIMILE was removed (see above in "loadTimeplot")
		/*
		(new DynaJsLoader()).loadScripts([{
			url : GeoTemCoLoader.urlPrefix + 'js/Time/' + 'SimileTimeplotModify.js'
		}]);
		*/
		(new DynaJsLoader()).loadScripts([{
			url : GeoTemCoLoader.urlPrefix + 'lib/' + 'openlayers/' + 'OpenLayers.js'
		}]);

		var geoTemCoFiles = [{
			url : GeoTemCoLoader.urlPrefix + 'js/Util/' + 'Tooltips.js'
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/' + 'GeoTemConfig.js',
			test : "GeoTemConfig.loadKml"
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'MapControl.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'CircleObject.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Util/' + 'FilterBar.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Util/' + 'Selection.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'PlacenameTags.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'MapConfig.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'MapGui.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'MapWidget.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Time/' + 'TimeConfig.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Time/' + 'TimeGui.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Time/' + 'TimeWidget.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Table/' + 'TableConfig.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Table/' + 'TableGui.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Table/' + 'TableWidget.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Table/' + 'Table.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Util/' + 'DataObject.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Util/' + 'Dataset.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Time/' + 'TimeDataSource.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'Binning.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'MapDataSource.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'Clustering.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Util/' + 'Dropdown.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'MapZoomSlider.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'MapPopup.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Map/' + 'PlacenamePopup.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Util/Publisher.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Util/WidgetWrapper.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Dataloader/' + 'DataloaderConfig.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Dataloader/' + 'DataloaderGui.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Dataloader/' + 'DataloaderWidget.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Dataloader/' + 'Dataloader.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Overlayloader/' + 'OverlayloaderConfig.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Overlayloader/' + 'OverlayloaderGui.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Overlayloader/' + 'OverlayloaderWidget.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Overlayloader/' + 'Overlayloader.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/PieChart/' + 'PieChartConfig.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/PieChart/' + 'PieChartGui.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/PieChart/' + 'PieChartWidget.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/PieChart/' + 'PieChart.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/PieChart/' + 'PieChartCategoryChooser.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/PieChart/' + 'PieChartHashFunctions.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Placetable/' + 'PlacetableConfig.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Placetable/' + 'PlacetableGui.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Placetable/' + 'PlacetableWidget.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Placetable/' + 'Placetable.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/LineOverlay/' + 'LineOverlayConfig.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/LineOverlay/' + 'LineOverlayWidget.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/LineOverlay/' + 'LineOverlay.js',
		}, {			
			url : GeoTemCoLoader.urlPrefix + 'js/FuzzyTimeline/' + 'FuzzyTimelineConfig.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/FuzzyTimeline/' + 'FuzzyTimelineGui.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/FuzzyTimeline/' + 'FuzzyTimelineWidget.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/FuzzyTimeline/' + 'FuzzyTimelineDensity.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/FuzzyTimeline/' + 'FuzzyTimelineRangeSlider.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/FuzzyTimeline/' + 'FuzzyTimelineRangePiechart.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/FuzzyTimeline/' + 'FuzzyTimelineRangeBars.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Storytelling/' + 'StorytellingConfig.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Storytelling/' + 'StorytellingGui.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Storytelling/' + 'StorytellingWidget.js',
		}, {
			url : GeoTemCoLoader.urlPrefix + 'js/Storytelling/' + 'Storytelling.js',
		}];
		(new DynaJsLoader()).loadScripts(geoTemCoFiles, GeoTemCoLoader.initGeoTemCo);

	},

	initGeoTemCo : function() {

		GeoTemConfig.configure(GeoTemCoLoader.urlPrefix);
		Publisher.Publish('GeoTemCoReady', '', null);
		
		//TODO: find more appropriate position for this
		$(window).resize(function() {
		    Publisher.Publish("resizeWidget");
		});
	}
}

GeoTemCoLoader.load();
