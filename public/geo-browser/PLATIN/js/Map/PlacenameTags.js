/*
* PlacenameTags.js
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
 * @class PlacenameTags
 * place labels computation for circles
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
function PlacenameTags(circle, map) {

	this.circle = circle;
	this.map = map;

	this.placeLabels
	this.selectedLabel

	this.allLabel
	this.othersLabel
	this.unknownLabel

	this.calculate = function() {
		this.calculateLabels();
		this.calculatePlacenameTags();
	}

	this.calculateLabels = function() {
		var elements = this.circle.elements;
		var k = this.circle.search;
		var weight = 0;
		var labels = [];
		
		var levelOfDetail = 0;
		if (this.map.options.placenameTagsStyle === 'zoom')
			levelOfDetail = this.map.getLevelOfDetail();

		if (this.map.options.placenameTagsStyle === 'value'){
			//find max level that _all_ elements have a value for
			var maxLevel;
			for (var i = 0; i < elements.length; i++) {
				var level = elements[i].placeDetails[this.map.options.mapIndex].length-1;
				 
				if (typeof maxLevel === "undefined")
					maxLevel = level;
				if (maxLevel > level)
					maxLevel = level;
				//smallest level anyway, no need to look any further
				if (level == 0)
					break;
			}
			//search for highest level where the values differ
			for (levelOfDetail = 0; levelOfDetail < maxLevel; levelOfDetail++){
				var differenceFound = false;
				for (var i = 0; i < (elements.length-1); i++) {
					if (	elements[i].getPlace(this.map.options.mapIndex, levelOfDetail) !== 
							elements[i+1].getPlace(this.map.options.mapIndex, levelOfDetail))
						differenceFound = true;
				}
				if (differenceFound === true) 
					break;
			}			
		}
		
		for (var i = 0; i < elements.length; i++) {
			weight += elements[i].weight;
			var found = false;
			var label = elements[i].getPlace(this.map.options.mapIndex, levelOfDetail);
			if (label == "") {
				label = "unknown";
			}
			for (var j = 0; j < labels.length; j++) {
				if (labels[j].place == label) {
					labels[j].elements.push(elements[i]);
					labels[j].weight += elements[i].weight;
					found = true;
					break;
				}
			}
			if (!found) {
				labels.push({
					id : elements[i].name,
					place : label,
					elements : new Array(elements[i]),
					weight : elements[i].weight,
					index : k
				});
			}
		}
		var sortBySize = function(label1, label2) {
			if (label1.weight > label2.weight) {
				return -1;
			}
			return 1;
		}
		labels.sort(sortBySize);
		if (map.options.maxPlaceLabels) {
			var ml = map.options.maxPlaceLabels;
			if (ml == 1) {
				labels = [];
				labels.push({
					place : "all",
					elements : elements,
					weight : weight,
					index : k
				});
			}
			if (ml == 2) {
				ml++;
			}
			if (ml > 2 && labels.length + 1 > ml) {
				var c = [];
				var w = 0;
				for (var i = ml - 2; i < labels.length; i++) {
					c = c.concat(labels[i].elements);
					w += labels[i].weight;
				}
				labels = labels.slice(0, ml - 2);
				labels.push({
					place : "others",
					elements : c,
					weight : w,
					index : k
				});
			}
		}
		if (labels.length > 1) {
			labels.push({
				place : "all",
				elements : elements,
				weight : weight,
				index : k
			});
		}
		this.placeLabels = labels;
	};

	this.calculatePlacenameTags = function() {
		var cloud = this;
		var c = GeoTemConfig.getColor(this.circle.search);
		if( map.options.useGraphics ){
			c = map.config.getGraphic(this.circle.search).color;
		}
		var color0 = 'rgb(' + c.r0 + ',' + c.g0 + ',' + c.b0 + ')';
		var color1 = 'rgb(' + c.r1 + ',' + c.g1 + ',' + c.b1 + ')';
		var allStyles = "", hoverStyle = "", highlightStyle = "", selectedStyle = "", unselectedStyle = "";

		if (GeoTemConfig.ie) {
			highlightStyle += map.options.ieHighlightLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
			hoverStyle += map.options.ieHoveredLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
			selectedStyle += map.options.ieSelectedLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
			unselectedStyle += map.options.ieUnselectedLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
		} else {
			highlightStyle += map.options.highlightLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
			hoverStyle += map.options.hoveredLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
			selectedStyle += map.options.selectedLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
			unselectedStyle += map.options.unselectedLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
		}

		var clickFunction = function(label) {
			label.div.onclick = function() {
				cloud.changeLabelSelection(label);
			}
		}
		var maxLabelSize = this.count
		for (var i = 0; i < this.placeLabels.length; i++) {
			var l = this.placeLabels[i];
			l.selected = false;
			var div = document.createElement("div");
			div.setAttribute('class', 'tagCloudItem');
			var fontSize = 1 + (l.weight - 1) / this.map.count * map.options.maxLabelIncrease;
			if (l.place == "all") {
				fontSize = 1;
			}
			div.style.fontSize = fontSize + "em";
			l.allStyle = allStyles + "font-size: " + fontSize + "em;";
			l.selectedStyle = selectedStyle;
			l.unselectedStyle = unselectedStyle;
			l.highlightStyle = highlightStyle;
			l.hoverStyle = hoverStyle;
			div.innerHTML = l.place + "<span style='font-size:" + (1 / fontSize) + "em'>&nbsp;(" + l.weight + ")</span>";
			l.div = div;
			clickFunction(l);
		}
		if (map.options.labelGrid) {
			this.showPlacelabels();
		} else {
			for (var i = 0; i < this.placeLabels.length; i++) {
				this.placeLabels[i].div.setAttribute('style', this.placeLabels[i].allStyle + "" + this.placeLabels[i].highlightStyle);
			}
		}
	};

	this.selectLabel = function(label) {
		if ( typeof label == 'undefined') {
			label = this.placeLabels[this.placeLabels.length - 1];
		}
		if (this.map.popup) {
			this.map.popup.showLabelContent(label);
		}
		this.selectedLabel = label;
		this.selectedLabel.div.setAttribute('style', this.selectedLabel.allStyle + "" + this.selectedLabel.selectedStyle);
		this.map.mapLabelSelection(label);
	};

	// changes selection between labels (click, hover)
	this.changeLabelSelection = function(label) {
		if (this.selectedLabel == label) {
			return;
		}
		if ( typeof this.selectedLabel != 'undefined') {
			this.selectedLabel.div.setAttribute('style', this.selectedLabel.allStyle + "" + this.selectedLabel.unselectedStyle);
		}
		this.selectLabel(label);
	};

	this.showPlacelabels = function() {
		this.leftDiv = document.createElement("div");
		this.leftDiv.setAttribute('class', 'tagCloudDiv');
		this.map.gui.mapWindow.appendChild(this.leftDiv);
		this.rightDiv = document.createElement("div");
		this.rightDiv.setAttribute('class', 'tagCloudDiv');
		this.map.gui.mapWindow.appendChild(this.rightDiv);
		for (var i = 0; i < this.placeLabels.length; i++) {
			if (i % 2 == 0) {
				this.leftDiv.appendChild(this.placeLabels[i].div);
			} else {
				this.rightDiv.appendChild(this.placeLabels[i].div);
			}
			this.placeLabels[i].div.setAttribute('style', this.placeLabels[i].allStyle + "" + this.placeLabels[i].highlightStyle);
		}
		this.placeTagCloud();
	};

	this.placeTagCloud = function() {
		var lonlat = new OpenLayers.LonLat(this.circle.feature.geometry.x, this.circle.feature.geometry.y);
		var pixel = map.openlayersMap.getPixelFromLonLat(lonlat);
		var radius = this.circle.feature.style.pointRadius;
		var lw = this.leftDiv.offsetWidth;
		var rw = this.rightDiv.offsetWidth;
		this.leftDiv.style.left = (pixel.x - radius - lw - 5) + "px";
		this.rightDiv.style.left = (pixel.x + radius + 5) + "px";
		var lh = this.leftDiv.offsetHeight;
		var rh = this.rightDiv.offsetHeight;
		var lt = pixel.y - lh / 2;
		var rt = pixel.y - rh / 2;
		this.leftDiv.style.top = lt + "px";
		this.rightDiv.style.top = rt + "px";
	};

	this.remove = function() {
		$(this.leftDiv).remove();
		$(this.rightDiv).remove();
	};

};

function PackPlacenameTags(circle, map) {

	this.circle = circle;
	this.map = map;

	this.placeLabels
	this.selectedLabel

	this.allLabel
	this.othersLabel
	this.unknownLabel

	this.calculate = function() {
		this.calculateLabels();
		this.calculatePlacenameTags();
	}

	this.getLabelList = function(circle) {

		var elements = circle.elements;
		var k = circle.search;
		var weight = 0;
		var labels = [];
		var levelOfDetail = this.map.getLevelOfDetail();
		for (var i = 0; i < elements.length; i++) {
			weight += elements[i].weight;
			var found = false;
			var label = elements[i].getPlace(this.map.options.mapIndex, levelOfDetail);
			if (label == "") {
				label = "unknown";
			}
			for (var j = 0; j < labels.length; j++) {
				if (labels[j].place == label) {
					labels[j].elements.push(elements[i]);
					labels[j].weight += elements[i].weight;
					found = true;
					break;
				}
			}
			if (!found) {
				labels.push({
					id : elements[i].name,
					place : label,
					elements : new Array(elements[i]),
					weight : elements[i].weight,
					index : k
				});
			}
		}
		var sortBySize = function(label1, label2) {
			if (label1.weight > label2.weight) {
				return -1;
			}
			return 1;
		}
		labels.sort(sortBySize);
		var droppedLabels = [];
		if (map.options.maxPlaceLabels) {
			var ml = map.options.maxPlaceLabels;
			if (ml == 1) {
				labels = [];
				labels.push({
					place : "all",
					elements : elements,
					weight : weight,
					index : k
				});
			}
			if (ml == 2) {
				ml++;
			}
			if (ml > 2 && labels.length + 1 > ml) {
				var c = [];
				var w = 0;
				for (var i = ml - 2; i < labels.length; i++) {
					c = c.concat(labels[i].elements);
					w += labels[i].weight;
					droppedLabels.push(labels[i]);
				}
				labels = labels.slice(0, ml - 2);
				var ol = {
					place : "others",
					elements : c,
					weight : w,
					index : k
				};
				labels.push(ol);
				this.othersLabels.push(ol);
			}
		}
		if (labels.length > 1) {
			labels.push({
				place : "all",
				elements : elements,
				weight : weight,
				index : k
			});
		}
		this.placeLabels.push(labels);
		this.droppedLabels.push(droppedLabels);
	};

	this.calculateLabels = function() {
		var circles = this.circle.circles;
		this.placeLabels = [];
		this.droppedLabels = [];
		this.othersLabels = [];
		for (var i = 0; i < circles.length; i++) {
			this.getLabelList(circles[i]);
		}
	};

	this.calculatePlacenameTags = function() {
		var cloud = this;

		var unselectedStyles = [];
		var selectedStyles = [];
		var hoverStyles = [];

		for (var k = 0; k < this.placeLabels.length; k++) {
			var c = GeoTemConfig.getColor(this.circle.circles[k].search);
			if( map.options.useGraphics ){
				c = map.config.getGraphic(this.circle.circles[k].search).color;
			}
			var color0 = 'rgb(' + c.r0 + ',' + c.g0 + ',' + c.b0 + ')';
			var color1 = 'rgb(' + c.r1 + ',' + c.g1 + ',' + c.b1 + ')';
			var allStyles = "", hoverStyle = "", highlightStyle = "", selectedStyle = "", unselectedStyle = "";

			if (GeoTemConfig.ie) {
				highlightStyle += map.options.ieHighlightLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
				hoverStyle += map.options.ieHoveredLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
				selectedStyle += map.options.ieSelectedLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
				unselectedStyle += map.options.ieUnselectedLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
			} else {
				highlightStyle += map.options.highlightLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
				hoverStyle += map.options.hoveredLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
				selectedStyle += map.options.selectedLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
				unselectedStyle += map.options.unselectedLabel.replace(/COLOR1/g, color1).replace(/COLOR0/g, color0) + ";";
			}

			allStyles += 'margin-right:5px;';
			allStyles += 'margin-left:5px;';
			unselectedStyles.push(unselectedStyle);
			selectedStyles.push(selectedStyle);
			hoverStyles.push(hoverStyle);

			var clickFunction = function(label, id) {
				label.div.onmouseover = function() {
					if (!label.opposite) {
						var oppositeLabel, oppositeLabelDiv;
						label.div.setAttribute('style', allStyles + "" + selectedStyles[id]);
						var c = GeoTemConfig.getColor(id);
						if( map.options.useGraphics ){
							c = map.config.getGraphic(id).color;
						}
						var color0 = 'rgb(' + c.r0 + ',' + c.g0 + ',' + c.b0 + ')';
						if (id == 0) {
							for (var i = 0; i < cloud.droppedLabels[1].length; i++) {
								if (cloud.droppedLabels[1][i].place == label.place) {
									oppositeLabel = cloud.droppedLabels[1][i];
									cloud.rightDiv.appendChild(oppositeLabel.div);
									cloud.drawLine(cloud.ctxOl, label.div, oppositeLabel.div);
									var olDiv = cloud.othersLabels[1].div;
									olDiv.innerHTML = olDiv.innerHTML.replace(/\(\d*\)/g, '(' + (cloud.othersLabels[1].weight - oppositeLabel.weight) + ')');
									break;
								}
							}
						} else {
							for (var i = 0; i < cloud.droppedLabels[0].length; i++) {
								if (cloud.droppedLabels[0][i].place == label.place) {
									oppositeLabel = cloud.droppedLabels[0][i];
									cloud.leftDiv.appendChild(oppositeLabel.div);
									cloud.drawLine(cloud.ctxOl, oppositeLabel.div, label.div);
									var olDiv = cloud.othersLabels[0].div;
									olDiv.innerHTML = olDiv.innerHTML.replace(/\(\d*\)/g, '(' + (cloud.othersLabels[0].weight - oppositeLabel.weight) + ')');
									break;
								}
							}
						}
						if ( typeof oppositeLabel == 'undefined') {
							oppositeLabel = {
								div : cloud.naDiv
							};
							if (id == 0) {
								cloud.rightDiv.appendChild(cloud.naDiv);
								cloud.drawLine(cloud.ctxOl, label.div, cloud.naDiv);
								oppositeLabel.div.setAttribute('style', allStyles + "" + selectedStyles[1]);
							} else {
								cloud.leftDiv.appendChild(cloud.naDiv);
								cloud.drawLine(cloud.ctxOl, cloud.naDiv, label.div);
								oppositeLabel.div.setAttribute('style', allStyles + "" + selectedStyles[0]);
							}
							cloud.map.mapLabelHighlight(label);
						} else {
							cloud.map.mapLabelHighlight([label, oppositeLabel]);
						}
						label.div.onmouseout = function() {
							label.div.setAttribute('style', allStyles + "" + unselectedStyles[id]);
							var olDiv = cloud.othersLabels[0].div;
							olDiv.innerHTML = olDiv.innerHTML.replace(/\(\d*\)/g, '(' + cloud.othersLabels[0].weight + ')');
							var olDiv2 = cloud.othersLabels[1].div;
							olDiv2.innerHTML = olDiv2.innerHTML.replace(/\(\d*\)/g, '(' + cloud.othersLabels[1].weight + ')');
							$(oppositeLabel.div).remove();
							cloud.ctxOl.clearRect(0, 0, cloud.cvOl.width, cloud.cvOl.height);
							cloud.map.mapLabelHighlight();
						}
					}
				}
			}
			var maxLabelSize = this.count
			for (var i = 0; i < this.placeLabels[k].length; i++) {
				var l = this.placeLabels[k][i];
				l.selected = false;
				var div = document.createElement("div");
				div.setAttribute('class', 'tagCloudItem');
				var fontSize = 1 + (l.weight - 1) / this.map.count * map.options.maxLabelIncrease;
				if (l.place == "all") {
					fontSize = 1;
				}
				div.style.fontSize = fontSize + "em";
				l.allStyle = allStyles + "font-size: " + fontSize + "em;";
				l.selectedStyle = selectedStyle;
				l.unselectedStyle = unselectedStyle;
				l.hoverStyle = hoverStyle;
				div.innerHTML = l.place + "<span style='font-size:" + (1 / fontSize) + "em'>&nbsp;(" + l.weight + ")</span>";
				l.div = div;
				clickFunction(l, k);
			}
			for (var i = 0; i < this.droppedLabels[k].length; i++) {
				var l = this.droppedLabels[k][i];
				l.selected = false;
				var div = document.createElement("div");
				div.setAttribute('class', 'tagCloudItem');
				var fontSize = 1 + (l.weight - 1) / this.map.count * map.options.maxLabelIncrease;
				div.style.fontSize = fontSize + "em";
				l.allStyle = allStyles + "font-size: " + fontSize + "em;";
				l.selectedStyle = selectedStyle;
				l.unselectedStyle = unselectedStyle;
				l.hoverStyle = hoverStyle;
				div.innerHTML = l.place + "<span style='font-size:" + (1 / fontSize) + "em'>&nbsp;(" + l.weight + ")</span>";
				l.div = div;
				div.setAttribute('style', allStyles + "" + selectedStyle);
			}
		}

		this.naDiv = document.createElement("div");
		this.naDiv.setAttribute('class', 'tagCloudItem');
		var fontSize = 1;
		div.style.fontSize = fontSize + "em";
		l.allStyle = allStyles + "font-size: " + fontSize + "em;";
		l.selectedStyle = selectedStyle;
		l.unselectedStyle = unselectedStyle;
		l.hoverStyle = hoverStyle;
		this.naDiv.innerHTML = "Not available";
		l.div = this.naDiv;

		if (map.options.labelGrid) {
			this.showPlacelabels();
		}
	};

	this.showPlacelabels = function() {
		this.leftDiv = document.createElement("div");
		this.leftDiv.setAttribute('class', 'tagCloudDiv');
		this.leftDiv.style.textAlign = 'right';
		this.map.gui.mapWindow.appendChild(this.leftDiv);
		this.centerDiv = document.createElement("div");
		this.centerDiv.setAttribute('class', 'tagCloudDiv');
		this.centerDiv.style.opacity = 0.7;
		this.map.gui.mapWindow.appendChild(this.centerDiv);
		this.centerDivOl = document.createElement("div");
		this.centerDivOl.setAttribute('class', 'tagCloudDiv');
		this.centerDivOl.style.opacity = 0.7;
		this.map.gui.mapWindow.appendChild(this.centerDivOl);
		this.rightDiv = document.createElement("div");
		this.rightDiv.setAttribute('class', 'tagCloudDiv');
		this.rightDiv.style.textAlign = 'left';
		this.map.gui.mapWindow.appendChild(this.rightDiv);
		for (var i = 0; i < this.placeLabels.length; i++) {
			for (var j = 0; j < this.placeLabels[i].length; j++) {
				if (i == 0) {
					this.leftDiv.appendChild(this.placeLabels[i][j].div);
				} else {
					this.rightDiv.appendChild(this.placeLabels[i][j].div);
				}
				this.placeLabels[i][j].div.setAttribute('style', this.placeLabels[i][j].allStyle + "" + this.placeLabels[i][j].unselectedStyle);
			}
		}
		this.placeTagCloud();
		this.setCanvas();
	};

	this.placeTagCloud = function() {
		var lonlat = new OpenLayers.LonLat(this.circle.feature.geometry.x, this.circle.feature.geometry.y);
		var pixel = map.openlayersMap.getPixelFromLonLat(lonlat);
		var radius = this.circle.feature.style.pointRadius;
		var lw = this.leftDiv.offsetWidth;
		var rw = this.rightDiv.offsetWidth;
		this.leftDiv.style.left = (pixel.x - radius - lw - 5) + "px";
		this.rightDiv.style.left = (pixel.x + radius + 5) + "px";
		var lh = this.leftDiv.offsetHeight;
		var rh = this.rightDiv.offsetHeight;
		var lt = pixel.y - lh / 2;
		var rt = pixel.y - rh / 2;
		this.leftDiv.style.top = lt + "px";
		this.rightDiv.style.top = rt + "px";
	};

	this.setCanvas = function() {
		var height = Math.max(this.leftDiv.offsetHeight, this.rightDiv.offsetHeight);
		var top = Math.min(this.leftDiv.offsetTop, this.rightDiv.offsetTop);
		var left = this.leftDiv.offsetLeft + this.leftDiv.offsetWidth;
		this.width = this.rightDiv.offsetLeft - left;
		this.centerDiv.style.left = left + "px";
		this.centerDiv.style.top = top + "px";
		this.centerDiv.style.height = height + "px";
		this.centerDiv.style.width = this.width + "px";

		this.centerDivOl.style.left = left + "px";
		this.centerDivOl.style.top = top + "px";
		this.centerDivOl.style.height = height + "px";
		this.centerDivOl.style.width = this.width + "px";

		var cv = document.createElement("canvas");
		this.centerDiv.appendChild(cv);
		if (!cv.getContext && G_vmlCanvasManager) {
			cv = G_vmlCanvasManager.initElement(cv);
		}
		cv.width = this.width;
		cv.height = height;
		ctx = cv.getContext('2d');

		this.cvOl = document.createElement("canvas");
		this.centerDivOl.appendChild(this.cvOl);
		if (!this.cvOl.getContext && G_vmlCanvasManager) {
			this.cvOl = G_vmlCanvasManager.initElement(this.cvOl);
		}
		this.cvOl.width = this.width;
		this.cvOl.height = height + 50;
		this.ctxOl = this.cvOl.getContext('2d');

		for (var i = 0; i < this.placeLabels[0].length; i++) {
			this.placeLabels[0][i].opposite = false;
		}
		for (var i = 0; i < this.placeLabels[1].length; i++) {
			this.placeLabels[1][i].opposite = false;
		}
		for (var i = 0; i < this.placeLabels[0].length; i++) {
			for (var j = 0; j < this.placeLabels[1].length; j++) {
				if (this.placeLabels[0][i].place == this.placeLabels[1][j].place) {
					this.drawLine(ctx, this.placeLabels[0][i].div, this.placeLabels[1][j].div);
					this.placeLabels[0][i].opposite = true;
					this.placeLabels[1][j].opposite = true;
				}
			}
		}
	}

	this.drawLine = function(ctx, label1, label2) {
		var x1 = 5;
		var x2 = this.width - 5;
		var y1 = label1.offsetTop + label1.offsetHeight / 2;
		var y2 = label2.offsetTop + label2.offsetHeight / 2;
		if (this.leftDiv.offsetTop > this.rightDiv.offsetTop) {
			y1 += this.leftDiv.offsetTop - this.rightDiv.offsetTop;
		} else {
			y2 += this.rightDiv.offsetTop - this.leftDiv.offsetTop;
		}
		ctx.lineCap = 'round';
		ctx.lineWidth = 5;
		ctx.beginPath();
		ctx.moveTo(x1, y1);
		ctx.lineTo(x2, y2);
		ctx.strokeStyle = '#555';
		ctx.stroke();
	}

	this.remove = function() {
		$(this.leftDiv).remove();
		$(this.rightDiv).remove();
		$(this.centerDiv).remove();
		$(this.centerDivOl).remove();
	};

};
