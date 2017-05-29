/*
* FuzzyTimelineGui.js
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
 * @class FuzzyTimelineGui
 * FuzzyTimeline GUI Implementation
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 *
 * @param {FuzzyTimelineWidget} parent FuzzyTimeline widget object
 * @param {HTML object} div parent div to append the FuzzyTimeline gui
 * @param {JSON} options FuzzyTimeline configuration
 */
function FuzzyTimelineGui(fuzzyTimelineWidget, div, options) {

	this.parent = fuzzyTimelineWidget;
	var fuzzyTimelineGui = this;
	
	this.fuzzyTimelineContainer = div;
	//if no height is given, draw it in a 32/9 ratio 
	if ($(this.fuzzyTimelineContainer).height() === 0)
		$(this.fuzzyTimelineContainer).height($(this.fuzzyTimelineContainer).width()*9/32);
	//this.fuzzyTimelineContainer.style.position = 'relative';

	this.sliderTable = document.createElement("table");
	$(this.sliderTable).addClass("ddbToolbar");
	$(this.sliderTable).width("100%");
	$(this.sliderTable).height("49px");
	div.appendChild(this.sliderTable);
	
	this.plotDIVHeight = $(this.fuzzyTimelineContainer).height()-$(this.sliderTable).height();
	var plotScrollContainer = $("<div></div>");
	plotScrollContainer.css("overflow-x","auto");
	plotScrollContainer.css("overflow-y","hidden");
	plotScrollContainer.width("100%");
	plotScrollContainer.height(this.plotDIVHeight);
	$(div).append(plotScrollContainer);
	this.plotDiv = document.createElement("div");
	$(this.plotDiv).width("100%");
	$(this.plotDiv).height(this.plotDIVHeight);
	plotScrollContainer.append(this.plotDiv);
	if (this.parent.options.showRangePiechart){
		this.rangePiechartDiv = document.createElement("div");
		$(this.rangePiechartDiv).css("float","right");
		//alter plot div width (leave space for piechart)
		$(this.plotDiv).width("75%");
		$(this.rangePiechartDiv).width("25%");
		$(this.rangePiechartDiv).height(plotDIVHeight);
		div.appendChild(this.rangePiechartDiv);
	}
};

FuzzyTimelineGui.prototype = {
};