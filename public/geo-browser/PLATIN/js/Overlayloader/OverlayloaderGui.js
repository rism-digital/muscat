/*
* OverlayloaderGui.js
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
 * @class OverlayloaderGui
 * Overlayloader GUI Implementation
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {OverlayloaderWidget} parent Overlayloader widget object
 * @param {HTML object} div parent div to append the Overlayloader gui
 * @param {JSON} options Overlayloader configuration
 */
function OverlayloaderGui(overlayloader, div, options) {

	this.parent = overlayloader;
	var overlayloaderGui = this;
	
	this.overlayloaderContainer = div;
	this.overlayloaderContainer.style.position = 'relative';

	this.loaderTypeSelect = document.createElement("select");
	div.appendChild(this.loaderTypeSelect);
	
	this.loaders = document.createElement("div");
	div.appendChild(this.loaders);
	
	this.overlayList = document.createElement("div");
	div.appendChild(this.overlayList);
	
	$(this.loaderTypeSelect).change(function(){
		var activeLoader = $(this).val();
		$(overlayloaderGui.loaders).find("div").each(function(){
			if ($(this).attr("id") == activeLoader)
				$(this).show();
			else
				$(this).hide();
		});
	});
	
	this.refreshOverlayList = function(){
		var overlayloaderGui = this;
		
		$(overlayloaderGui.overlayList).empty();
		$(this.parent.overlayLoader.overlays).each(function(){
			var overlay = this;
			$(overlayloaderGui.overlayList).append(overlay.name);
			var link = document.createElement("a");
			$(link).text("(x)");
			link.href="";
			
			$(link).click($.proxy(function(){
				$(overlay.layers).each(function(){
					this.map.removeLayer(this.layer);
				});
				
				var overlays = overlayloaderGui.parent.overlayLoader.overlays;
				
				overlays = $.grep(overlays, function(value) {
				    return overlay != value;
				});
				
				overlayloaderGui.parent.overlayLoader.overlays = overlays;
				
				overlayloaderGui.refreshOverlayList();
				
				return(false);
			},{overlay:overlay,overlayloaderGui:overlayloaderGui}));
			$(overlayloaderGui.overlayList).append(link);
		});
	};
};
