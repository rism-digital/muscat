/*
* Binning.js
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
 * @class Binning
 * Calculates map aggregation with several binning algorithms
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
Binning = function(map, options) {

	this.map = map;
	this.options = options;
	this.reset();

};

Binning.prototype = {

	getSet : function() {
		var type = this.options.binning;
		if (!type) {
			return this.getExactBinning();
		} else if (type == 'generic') {
			return this.getGenericBinning();
		} else if (type == 'square') {
			return this.getSquareBinning();
		} else if (type == 'hexagonal') {
			return this.getHexagonalBinning();
		} else if (type == 'triangular') {
			return this.getTriangularBinning();
		}
	},

	getExactBinning : function() {
		if ( typeof this.binnings['exact'] == 'undefined') {
			this.exactBinning();
		}
		return this.binnings['exact'];
	},

	getGenericBinning : function() {
		if ( typeof this.binnings['generic'] == 'undefined') {
			this.genericBinning();
		}
		return this.binnings['generic'];
	},

	getSquareBinning : function() {
		if ( typeof this.binnings['square'] == 'undefined') {
			this.squareBinning();
		}
		return this.binnings['square'];
	},

	getHexagonalBinning : function() {
		if ( typeof this.binnings['hexagonal'] == 'undefined') {
			this.hexagonalBinning();
		}
		return this.binnings['hexagonal'];
	},

	getTriangularBinning : function() {
		if ( typeof this.binnings['triangular'] == 'undefined') {
			this.triangularBinning();
		}
		return this.binnings['triangular'];
	},

	reset : function() {
		this.zoomLevels = this.map.getNumZoomLevels();
		this.binnings = [];
		this.minimumRadius = this.options.minimumRadius;
		this.maximumRadius = this.minimumRadius;
		this.maximumPoints = 0;
		this.minArea = 0;
		this.maxArea = 0;
	},

	getMaxRadius : function(size) {
		return 4 * Math.log(size) / Math.log(2);
	},

	setObjects : function(objects) {
		this.objects = objects;
		for (var i = 0; i < this.objects.length; i++) {
			var weight = 0;
			for (var j = 0; j < this.objects[i].length; j++) {
				if (this.objects[i][j].isGeospatial) {
					weight += this.objects[i][j].weight;
				}
			}
			var r = this.getMaxRadius(weight);
			if (r > this.maximumRadius) {
				this.maximumRadius = r;
				this.maximumPoints = weight;
				this.maxArea = Math.PI * this.maximumRadius * this.maximumRadius;
				this.minArea = Math.PI * this.minimumRadius * this.minimumRadius;
			}
		}
	},

	dist : function(x1, y1, x2, y2) {
		return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
	},

	exactBinning : function() {
		var circleSets = [];
		var hashMaps = [];
		var selectionHashs = [];

		var circleAggregates = [];
		var bins = [];
		for (var i = 0; i < this.objects.length; i++) {
			bins.push([]);
			circleAggregates.push([]);
			for (var j = 0; j < this.objects[i].length; j++) {
				var o = this.objects[i][j];
				if (o.isGeospatial) {
					if ( typeof circleAggregates[i]['' + o.getLongitude(this.options.mapIndex)] == 'undefined') {
						circleAggregates[i]['' + o.getLongitude(this.options.mapIndex)] = [];
					}
					if ( typeof circleAggregates[i][''+o.getLongitude(this.options.mapIndex)]['' + o.getLatitude(this.options.mapIndex)] == 'undefined') {
						circleAggregates[i][''+o.getLongitude(this.options.mapIndex)]['' + o.getLatitude(this.options.mapIndex)] = [];
						bins[i].push(circleAggregates[i][''+o.getLongitude(this.options.mapIndex)]['' + o.getLatitude(this.options.mapIndex)]);
					}
					circleAggregates[i][''+o.getLongitude(this.options.mapIndex)]['' + o.getLatitude(this.options.mapIndex)].push(o);
				}
			}
		}

		var circles = [];
		var hashMap = [];
		var selectionMap = [];
		for (var i = 0; i < bins.length; i++) {
			circles.push([]);
			hashMap.push([]);
			selectionMap.push([]);
			for (var j = 0; j < bins[i].length; j++) {
				var bin = bins[i][j];
				var p = new OpenLayers.Geometry.Point(bin[0].getLongitude(this.options.mapIndex), bin[0].getLatitude(this.options.mapIndex), null);
				p.transform(this.map.displayProjection, this.map.projection);
				var weight = 0;
				for (var z = 0; z < bin.length; z++) {
					weight += bin[z].weight;
				}
				var radius = this.options.minimumRadius;
				if (this.options.noBinningRadii == 'dynamic') {
					radius = this.getRadius(weight);
				}
				var circle = new CircleObject(p.x, p.y, 0, 0, bin, radius, i, weight);
				circles[i].push(circle);
				for (var z = 0; z < bin.length; z++) {
					hashMap[i][bin[z].index] = circle;
					selectionMap[i][bin[z].index] = false;
				}
			}
		}
		for (var k = 0; k < this.zoomLevels; k++) {
			circleSets.push(circles);
			hashMaps.push(hashMap);
			selectionHashs.push(selectionMap);
		}
		this.binnings['exact'] = {
			circleSets : circleSets,
			hashMaps : hashMaps,
			selectionHashs : selectionHashs
		};
	},

	genericClustering : function(objects, id) {
		var binSets = [];
		var circleSets = [];
		var hashMaps = [];
		var selectionHashs = [];
		var clustering = new Clustering(-20037508.34, -20037508.34, 20037508.34, 20037508.34);
		for (var i = 0; i < objects.length; i++) {
			for (var j = 0; j < objects[i].length; j++) {
				var o = objects[i][j];
				if (o.isGeospatial) {
					var p = new OpenLayers.Geometry.Point(o.getLongitude(this.options.mapIndex), o.getLatitude(this.options.mapIndex), null);
					p.transform(this.map.displayProjection, this.map.projection);
					var point = new Vertex(Math.floor(p.x), Math.floor(p.y), objects.length, this);
					point.addElement(o, o.weight, i);
					clustering.add(point);
				}
			}
		}

		for (var i = 0; i < this.zoomLevels; i++) {
			var bins = [];
			var circles = [];
			var hashMap = [];
			var selectionMap = [];
			for (var j = 0; j < objects.length; j++) {
				circles.push([]);
				hashMap.push([]);
				selectionMap.push([]);
			}
			var resolution = this.map.getResolutionForZoom(this.zoomLevels - i - 1);
			clustering.mergeForResolution(resolution, this.options.circleGap, this.options.circleOverlap);
			for (var j = 0; j < clustering.vertices.length; j++) {
				var point = clustering.vertices[j];
				if (!point.legal) {
					continue;
				}
				var balls = [];
				for (var k = 0; k < point.elements.length; k++) {
					if (point.elements[k].length > 0) {
						balls.push({
							search : k,
							elements : point.elements[k],
							radius : point.radii[k],
							weight : point.weights[k]
						});
					}
				}
				var orderBalls = function(b1, b2) {
					if (b1.radius > b2.radius) {
						return -1;
					}
					if (b2.radius > b1.radius) {
						return 1;
					}
					return 0;
				}
				var fatherBin = {
					circles : [],
					length : 0,
					radius : point.radius / resolution,
					x : point.x,
					y : point.y
				};
				for (var k = 0; k < objects.length; k++) {
					fatherBin.circles.push(false);
				}
				var createCircle = function(sx, sy, ball) {
					var index = id || ball.search;
					var circle = new CircleObject(point.x, point.y, sx, sy, ball.elements, ball.radius, index, ball.weight, fatherBin);
					circles[ball.search].push(circle);
					fatherBin.circles[index] = circle;
					fatherBin.length++;
					for (var k = 0; k < ball.elements.length; k++) {
						hashMap[ball.search][ball.elements[k].index] = circle;
						selectionMap[ball.search][ball.elements[k].index] = false;
					}
				}
				if (balls.length == 1) {
					createCircle(0, 0, balls[0]);
				} else if (balls.length == 2) {
					var r1 = balls[0].radius;
					var r2 = balls[1].radius;
					createCircle(-1 * r2, 0, balls[0]);
					createCircle(r1, 0, balls[1]);
				} else if (balls.length == 3) {
					balls.sort(orderBalls);
					var r1 = balls[0].radius;
					var r2 = balls[1].radius;
					var r3 = balls[2].radius;
					var d = ((2 / 3 * Math.sqrt(3) - 1) / 2) * r2;
					var delta1 = point.radius / resolution - r1 - d;
					var delta2 = r1 - delta1;
					createCircle(-delta1, 0, balls[0]);
					createCircle(delta2 + r2 - 3 * d, r2, balls[1]);
					createCircle(delta2 + r2 - 3 * d, -1 * r3, balls[2]);
//					createCircle(delta2 + r3 - (3 * d * r3 / r2), -1 * r3, balls[2]);
				} else if (balls.length == 4) {
					balls.sort(orderBalls);
					var r1 = balls[0].radius;
					var r2 = balls[1].radius;
					var r3 = balls[2].radius;
					var r4 = balls[3].radius;
					var d = (Math.sqrt(2) - 1) * r2;
					createCircle(-1 * d - r2, 0, balls[0]);
					createCircle(r1 - r2, -1 * d - r4, balls[3]);
					createCircle(r1 - r2, d + r3, balls[2]);
					createCircle(d + r1, 0, balls[1]);
				}
				if (fatherBin.length > 1) {
					bins.push(fatherBin);
				}
			}
			circleSets.push(circles);
			binSets.push(bins);
			hashMaps.push(hashMap);
			selectionHashs.push(selectionMap);
		}
		circleSets.reverse();
		binSets.reverse();
		hashMaps.reverse();
		selectionHashs.reverse();
		return {
			circleSets : circleSets,
			binSets : binSets,
			hashMaps : hashMaps,
			selectionHashs : selectionHashs
		};
	},

	genericBinning : function() {
		if (this.options.circlePackings || this.objects.length == 1) {
			this.binnings['generic'] = this.genericClustering(this.objects);
		} else {
			var circleSets = [];
			var hashMaps = [];
			var selectionHashs = [];
			for (var i = 0; i < this.objects.length; i++) {
				var sets = this.genericClustering([this.objects[i]], i);
				if (i == 0) {
					circleSets = sets.circleSets;
					hashMaps = sets.hashMaps;
					selectionHashs = sets.selectionHashs;
				} else {
					for (var j = 0; j < circleSets.length; j++) {
						circleSets[j] = circleSets[j].concat(sets.circleSets[j]);
						hashMaps[j] = hashMaps[j].concat(sets.hashMaps[j]);
						selectionHashs[j] = selectionHashs[j].concat(sets.selectionHashs[j]);
					}
				}
			}
			this.binnings['generic'] = {
				circleSets : circleSets,
				hashMaps : hashMaps,
				selectionHashs : selectionHashs
			};
		}
	},

	getRadius : function(n) {
		if (n == 0) {
			return 0;
		}
		if (n == 1) {
			return this.minimumRadius;
		}
		return Math.sqrt((this.minArea + (this.maxArea - this.minArea) / (this.maximumPoints - 1) * (n - 1) ) / Math.PI);
	},

	getBinRadius : function(n, r_max, N) {
		if (n == 0) {
			return 0;
		}
		/*
		function log2(x) {
			return (Math.log(x)) / (Math.log(2));
		}
		var r0 = this.options.minimumRadius;
		var r;
		if ( typeof r_max == 'undefined') {
			return r0 + n / Math.sqrt(this.options.maximumPoints);
		}
		return r0 + (r_max - r0 ) * log2(n) / log2(N);
		*/
		var minArea = Math.PI * this.options.minimumRadius * this.options.minimumRadius;
		var maxArea = Math.PI * r_max * r_max;
		return Math.sqrt((minArea + (maxArea - minArea) / (N - 1) * (n - 1) ) / Math.PI);
	},

	shift : function(type, bin, radius, elements) {

		var x1 = bin.x, x2 = 0;
		var y1 = bin.y, y2 = 0;
		for (var i = 0; i < elements.length; i++) {
			x2 += elements[i].x / elements.length;
			y2 += elements[i].y / elements.length;
		}

		var sx = 0, sy = 0;

		if (type == 'square') {
			var dx = Math.abs(x2 - x1);
			var dy = Math.abs(y2 - y1);
			var m = dy / dx;
			var n = y1 - m * x1;
			if (dx > dy) {
				sx = bin.x - (x1 + bin.r - radius );
				sy = bin.y - (m * bin.x + n );
			} else {
				sy = bin.y - (y1 + bin.r - radius );
				sx = bin.x - (bin.y - n) / m;
			}
		}

		return {
			x : sx,
			y : sy
		};

	},

	binSize : function(elements) {
		var size = 0;
		for (var i in elements ) {
			size += elements[i].weight;
		}
		return size;
	},

	setCircleSet : function(id, binData) {
		var circleSets = [];
		var hashMaps = [];
		var selectionHashs = [];
		for (var i = 0; i < binData.length; i++) {
			var circles = [];
			var hashMap = [];
			var selectionMap = [];
			for (var j = 0; j < this.objects.length; j++) {
				circles.push([]);
				hashMap.push([]);
				selectionMap.push([]);
			}
			var points = [];
			var max = 0;
			var radius = 0;
			var resolution = this.map.getResolutionForZoom(i);
			for (var j = 0; j < binData[i].length; j++) {
				for (var k = 0; k < binData[i][j].bin.length; k++) {
					var bs = this.binSize(binData[i][j].bin[k]);
					if (bs > max) {
						max = bs;
						radius = binData[i][j].r / resolution;
					}
				}
			}
			for (var j = 0; j < binData[i].length; j++) {
				var bin = binData[i][j];
				for (var k = 0; k < bin.bin.length; k++) {
					if (bin.bin[k].length == 0) {
						continue;
					}
					var weight = this.binSize(bin.bin[k]);
					var r = this.getBinRadius(weight, radius, max);
					var shift = this.shift(id, bin, r * resolution, bin.bin[k], i);
					var circle = new CircleObject(bin.x - shift.x, bin.y - shift.y, 0, 0, bin.bin[k], r, k, weight);
					circles[k].push(circle);
					for (var z = 0; z < bin.bin[k].length; z++) {
						hashMap[k][bin.bin[k][z].index] = circle;
						selectionMap[k][bin.bin[k][z].index] = false;
					}
				}
			}
			circleSets.push(circles);
			hashMaps.push(hashMap);
			selectionHashs.push(selectionMap);
		}
		this.binnings[id] = {
			circleSets : circleSets,
			hashMaps : hashMaps,
			selectionHashs : selectionHashs
		};
	},

	squareBinning : function() {

		var l = 20037508.34;
		var area0 = l * l * 4;
		var binCount = this.options.binCount;

		var bins = [];
		var binData = [];
		for (var k = 0; k < this.zoomLevels; k++) {
			bins.push([]);
			binData.push([]);
		}

		for (var i = 0; i < this.objects.length; i++) {
			for (var j = 0; j < this.objects[i].length; j++) {
				var o = this.objects[i][j];
				if (!o.isGeospatial) {
					continue;
				}
				var p = new OpenLayers.Geometry.Point(o.getLongitude(this.options.mapIndex), o.getLatitude(this.options.mapIndex), null);
				p.transform(this.map.displayProjection, this.map.projection);
				o.x = p.x;
				o.y = p.y;
				for (var k = 0; k < this.zoomLevels; k++) {
					var bc = binCount * Math.pow(2, k);
					var a = 2 * l / bc;
					var binX = Math.floor((p.x + l) / (2 * l) * bc);
					var binY = Math.floor((p.y + l) / (2 * l) * bc);
					if ( typeof bins[k]['' + binX] == 'undefined') {
						bins[k]['' + binX] = [];
					}
					if ( typeof bins[k][''+binX]['' + binY] == 'undefined') {
						bins[k][''+binX]['' + binY] = [];
						for (var z = 0; z < this.objects.length; z++) {
							bins[k][''+binX]['' + binY].push([]);
						}
						var x = binX * a + a / 2 - l;
						var y = binY * a + a / 2 - l;
						binData[k].push({
							bin : bins[k][''+binX]['' + binY],
							x : x,
							y : y,
							a : a,
							r : a / 2
						});
					}
					bins[k][''+binX][''+binY][i].push(o);
				}
			}
		}

		this.setCircleSet('square', binData);

	},

	triangularBinning : function() {

		var l = 20037508.34;
		var a0 = this.options.binCount;
		var a1 = Math.sqrt(4 * a0 * a0 / Math.sqrt(3));
		var binCount = a0 / a1 * a0;

		var bins = [];
		var binData = [];
		for (var k = 0; k < this.zoomLevels; k++) {
			bins.push([]);
			binData.push([]);
		}

		for (var i = 0; i < this.objects.length; i++) {
			for (var j = 0; j < this.objects[i].length; j++) {
				var o = this.objects[i][j];
				if (!o.isGeospatial) {
					continue;
				}
				var p = new OpenLayers.Geometry.Point(o.getLongitude(this.options.mapIndex), o.getLatitude(this.options.mapIndex), null);
				p.transform(this.map.displayProjection, this.map.projection);
				o.x = p.x;
				o.y = p.y;
				for (var k = 0; k < this.zoomLevels; k++) {
					var x_bc = binCount * Math.pow(2, k);
					var y_bc = x_bc * x_bc / Math.sqrt(x_bc * x_bc - x_bc * x_bc / 4);
					var a = 2 * l / x_bc;
					var h = 2 * l / y_bc;
					var binY = Math.floor((p.y + l) / (2 * l) * y_bc);
					if ( typeof bins[k]['' + binY] == 'undefined') {
						bins[k]['' + binY] = [];
					}
					var triangleIndex;
					var partitionsX = x_bc * 2;
					var partition = Math.floor((p.x + l) / (2 * l) * partitionsX);
					var xMax = a / 2;
					var yMax = h;
					var x = p.x + l - partition * a / 2;
					var y = p.y + l - binY * h;
					if (binY % 2 == 0 && partition % 2 == 1 || binY % 2 == 1 && partition % 2 == 0) {
						if (y + yMax / xMax * x < yMax) {
							triangleIndex = partition;
						} else {
							triangleIndex = partition + 1;
						}
					} else {
						if (y > yMax / xMax * x) {
							triangleIndex = partition;
						} else {
							triangleIndex = partition + 1;
						}
					}
					if ( typeof bins[k][''+binY]['' + triangleIndex] == 'undefined') {
						bins[k][''+binY]['' + triangleIndex] = [];
						for (var z = 0; z < this.objects.length; z++) {
							bins[k][''+binY]['' + triangleIndex].push([]);
						}
						var r = Math.sqrt(3) / 6 * a;
						var x = (triangleIndex - 1) * a / 2 + a / 2 - l;
						var y;
						if (binY % 2 == 0 && triangleIndex % 2 == 0 || binY % 2 == 1 && triangleIndex % 2 == 1) {
							y = binY * h + h - r - l;
						} else {
							y = binY * h + r - l;
						}
						binData[k].push({
							bin : bins[k][''+binY]['' + triangleIndex],
							x : x,
							y : y,
							a : a,
							r : r
						});
					}
					bins[k][''+binY][''+triangleIndex][i].push(o);
				}
			}
		}

		this.setCircleSet('triangular', binData);

	},

	hexagonalBinning : function() {

		var l = 20037508.34;
		var a0 = this.options.binCount;
		var a2 = Math.sqrt(4 * a0 * a0 / Math.sqrt(3)) / Math.sqrt(6);
		var binCount = a0 / a2 * a0;

		var bins = [];
		var binData = [];
		for (var k = 0; k < this.zoomLevels; k++) {
			bins.push([]);
			binData.push([]);
		}

		for (var i = 0; i < this.objects.length; i++) {
			for (var j = 0; j < this.objects[i].length; j++) {
				var o = this.objects[i][j];
				if (!o.isGeospatial) {
					continue;
				}
				var p = new OpenLayers.Geometry.Point(o.getLongitude(this.options.mapIndex), o.getLatitude(this.options.mapIndex), null);
				p.transform(this.map.displayProjection, this.map.projection);
				o.x = p.x;
				o.y = p.y;
				for (var k = 0; k < this.zoomLevels; k++) {
					var x_bc = binCount * Math.pow(2, k);
					var y_bc = x_bc * x_bc / Math.sqrt(x_bc * x_bc - x_bc * x_bc / 4);
					var a = 2 * l / x_bc;
					var h = 2 * l / y_bc;
					var binY = Math.floor((p.y + l) / (2 * l) * y_bc);
					if ( typeof bins[k]['' + binY] == 'undefined') {
						bins[k]['' + binY] = [];
					}
					var triangleIndex;
					var partitionsX = x_bc * 2;
					var partition = Math.floor((p.x + l) / (2 * l) * partitionsX);
					var xMax = a / 2;
					var yMax = h;
					var x = p.x + l - partition * a / 2;
					var y = p.y + l - binY * h;
					if (binY % 2 == 0 && partition % 2 == 1 || binY % 2 == 1 && partition % 2 == 0) {
						if (y + yMax / xMax * x < yMax) {
							triangleIndex = partition;
						} else {
							triangleIndex = partition + 1;
						}
					} else {
						if (y > yMax / xMax * x) {
							triangleIndex = partition;
						} else {
							triangleIndex = partition + 1;
						}
					}
					if ( typeof bins[k][''+binY]['' + triangleIndex] == 'undefined') {
						bins[k][''+binY]['' + triangleIndex] = [];
						for (var z = 0; z < this.objects.length; z++) {
							bins[k][''+binY]['' + triangleIndex].push([]);
						}
						var r = Math.sqrt(3) / 6 * a;
						var x = (triangleIndex - 1) * a / 2 + a / 2 - l;
						var y;
						if (binY % 2 == 0 && triangleIndex % 2 == 0 || binY % 2 == 1 && triangleIndex % 2 == 1) {
							y = binY * h + h - r - l;
						} else {
							y = binY * h + r - l;
						}
						binData[k].push({
							bin : bins[k][''+binY]['' + triangleIndex],
							x : x,
							y : y,
							a : a,
							r : r,
							h : h,
							binX : triangleIndex,
							binY : binY
						});
					}
					bins[k][''+binY][''+triangleIndex][i].push(o);
				}
			}
		}

		var hexaBins = [];
		var hexaBinData = [];
		for (var k = 0; k < this.zoomLevels; k++) {
			hexaBins.push([]);
			hexaBinData.push([]);
		}

		for (var i = 0; i < binData.length; i++) {
			for (var j = 0; j < binData[i].length; j++) {
				var bin = binData[i][j];
				var binY = Math.floor(bin.binY / 2);
				var binX = Math.floor(bin.binX / 3);
				var x, y;
				var a = bin.a;
				var h = bin.h;
				if (bin.binX % 6 < 3) {
					if ( typeof hexaBins[i]['' + binY] == 'undefined') {
						hexaBins[i]['' + binY] = [];
					}
					y = binY * 2 * bin.h + bin.h - l;
					x = binX * 1.5 * bin.a + a / 2 - l;
				} else {
					if (bin.binY % 2 == 1) {
						binY++;
					}
					if ( typeof hexaBins[i]['' + binY] == 'undefined') {
						hexaBins[i]['' + binY] = [];
					}
					y = binY * 2 * bin.h - l;
					x = binX * 1.5 * bin.a + a / 2 - l;
				}
				if ( typeof hexaBins[i][''+binY]['' + binX] == 'undefined') {
					hexaBins[i][''+binY]['' + binX] = [];
					for (var z = 0; z < this.objects.length; z++) {
						hexaBins[i][''+binY]['' + binX].push([]);
					}
					hexaBinData[i].push({
						bin : hexaBins[i][''+binY]['' + binX],
						x : x,
						y : y,
						a : bin.a,
						r : bin.h
					});
				}
				for (var k = 0; k < bin.bin.length; k++) {
					for (var m = 0; m < bin.bin[k].length; m++) {
						hexaBins[i][''+binY][''+binX][k].push(bin.bin[k][m]);
					}
				}
			}
		}

		this.setCircleSet('hexagonal', hexaBinData);

	}
}

