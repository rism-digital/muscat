/*
* timeplot-ajax-basic.js
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
 * basic code which is included in front of timeplot code for the minified version
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */

if ( typeof window.Timeplot == "undefined") {
	window.Timeplot = {
		params : {
			bundle : true,
			autoCreate : true
		},
		namespace : "http://simile.mit.edu/2007/06/timeplot#",
		importers : {}
	};
	Timeplot.urlPrefix = GeoTemCoMinifier_urlPrefix + 'lib/simile/timeplot/';
}

