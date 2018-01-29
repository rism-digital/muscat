/*
* PlacenamePopup.js
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
 * @class PlacenamePopup
 * specific map popup for showing and interacting on placename labels
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
function PlacenamePopup(parent) {

	this.parentDiv = parent.gui.mapWindow;

	this.createPopup = function(x, y, labels) {
		this.labels = labels;
		var pnPopup = this;
		var popup = new MapPopup(parent);
		var onClose = function() {
			parent.deselection();
			pnPopup.reset();
		}
		popup.initialize(x, y, onClose);
		$.extend(this, popup);

		this.content = document.createElement("div");
		this.inner = document.createElement("div");

		this.resultsLabel = document.createElement("div");
		this.resultsLabel.setAttribute('class', 'popupDDBResults');
		this.content.appendChild(this.resultsLabel);
		this.backward = document.createElement("div");
		this.backward.setAttribute('class', 'prevItem');
		this.content.appendChild(this.backward);
		this.backward.onclick = function() {
			pnPopup.descriptionIndex--;
			pnPopup.showDescription();
		}

		this.number = document.createElement("div");
		this.content.appendChild(this.number);
		this.number.style.display = 'none';
		this.number.style.fontSize = '13px';

		this.forward = document.createElement("div");
		this.forward.setAttribute('class', 'nextItem');
		this.content.appendChild(this.forward);
		this.forward.onclick = function() {
			pnPopup.descriptionIndex++;
			pnPopup.showDescription();
		}
		if (parent.options.showDescriptions) {
			this.descriptions = document.createElement("div");
			this.descriptions.setAttribute('class', 'descriptions');
			this.descriptions.onclick = function() {
				pnPopup.switchToDescriptionMode();
			}
		}

		this.back = document.createElement("div");
		this.back.setAttribute('class', 'back');
		this.popupDiv.appendChild(this.back);
		this.back.onclick = function() {
			pnPopup.back.style.display = "none";
			pnPopup.backward.style.display = "none";
			pnPopup.forward.style.display = "none";
			pnPopup.number.style.display = 'none';
			pnPopup.showLabels();
		}

		this.content.appendChild(this.inner);
		this.listLabels();
		this.showLabels();

	};

	this.switchToDescriptionMode = function() {
		this.descriptionIndex = 0;
		this.descriptionContents = this.activeLabel.descriptions;
		this.number.style.display = 'inline-block';
		this.inner.style.minWidth = "300px";
		this.showDescription();
		this.count = this.activeLabel.weight;
		this.setCount();
		this.back.style.display = "inline-block";
	}

	this.showDescription = function() {
		$(this.inner).empty();
		this.inner.appendChild(this.descriptionContents[this.descriptionIndex]);
		this.setContent(this.content);
		if (this.descriptionContents.length == 1) {
			this.backward.style.display = "none";
			this.forward.style.display = "none";
		} else {
			if (this.descriptionIndex == 0) {
				this.backward.style.display = "none";
			} else {
				this.backward.style.display = "inline-block";
			}
			if (this.descriptionIndex == this.descriptionContents.length - 1) {
				this.forward.style.display = "none";
			} else {
				this.forward.style.display = "inline-block";
			}
		}
		if (this.descriptionContents.length > 1) {
			this.number.innerHTML = "#" + (this.descriptionIndex + 1);
		} else {
			this.number.style.display = 'none';
		}
		this.decorate();
	}

	this.setCount = function() {
		var c = this.count;
		if (c > 1) {
			this.resultsLabel.innerHTML = c + " " + GeoTemConfig.getString('results');
		} else {
			this.resultsLabel.innerHTML = c + " " + GeoTemConfig.getString('result');
		}
	}

	this.listLabels = function() {
		var pnPopup = this;
		this.labelDivs = [];
		this.labelCount = 0;
		this.labelsWidth = 0;
		for (var i = 0; i < this.labels.length; i++) {
			var div = document.createElement("div");
			var content = document.createElement("div");
			this.labels[i].allStyle += "position: relative; white-space: nowrap;";
			content.appendChild(this.labels[i].div);
			content.setAttribute('class', 'ddbPopupLabel');
			div.appendChild(content);
			this.labels[i].div.setAttribute('style', this.labels[i].allStyle + "" + this.labels[i].selectedStyle);
			this.input.appendChild(div);
			if (this.input.offsetWidth > this.labelsWidth) {
				this.labelsWidth = this.input.offsetWidth;
			}
			this.labels[i].div.setAttribute('style', this.labels[i].allStyle + "" + this.labels[i].unselectedStyle);
			this.labelDivs.push(div);
			var descriptions = [];
			for (var j = 0; j < this.labels[i].elements.length; j++) {
				var div = document.createElement("div");
				div.innerHTML = this.labels[i].elements[j].description;
				descriptions.push(div);
			}
			this.labels[i].descriptions = descriptions;
			if (this.labels[i].place != "all" || i == 0) {
				this.labelCount += this.labels[i].weight;
			}
		}
		if ( typeof this.descriptions != 'undefined') {
			this.labelsWidth += 20;
		}
	}

	this.showLabels = function() {
		$(this.inner).empty();
		this.count = this.labelCount;
		this.setCount();
		for (var i = 0; i < this.labelDivs.length; i++) {
			this.inner.appendChild(this.labelDivs[i]);
		}
		this.inner.style.width = this.labelsWidth + "px";
		this.inner.style.minWidth = this.labelsWidth + "px";
		this.setContent(this.content);
		this.decorate();
	}

	this.showLabelContent = function(label) {
		for (var i = 0; i < this.labels.length; i++) {
			if (this.labels[i] == label) {
				this.activeLabel = this.labels[i];
				if ( typeof this.descriptions != 'undefined') {
					this.labelDivs[i].appendChild(this.descriptions);
				}
				this.decorate();
				break;
			}
		}
	}

	this.setLanguage = function(language) {
		this.language = language;
		if (this.visible) {
			this.updateTexts();
		}
	}
};
