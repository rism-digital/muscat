/*
* basic.js
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
 * basic code which is included first for the minified version
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */

var arrayIndex = function(array, obj) {
	if (Array.indexOf) {
		return array.indexOf(obj);
	}
	for (var i = 0; i < array.length; i++) {
		if (array[i] == obj) {
			return i;
		}
	}
	return -1;
}
var GeoTemCoMinifier_urlPrefix;
for (var i = 0; i < document.getElementsByTagName("script").length; i++) {
	var script = document.getElementsByTagName("script")[i];
	var index = script.src.indexOf("platin.js");
	if (index == -1) {
		index = script.src.indexOf("platin-min.js");
	}
	if (index != -1) {
		GeoTemCoMinifier_urlPrefix = script.src.substring(0, index);
		break;
	}
}
