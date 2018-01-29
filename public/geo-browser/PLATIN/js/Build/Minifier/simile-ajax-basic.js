/*
* simile-ajax-basic.js
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
 * basic code which is included in front of simile ajax code for the minified version
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */

SimileAjax_urlPrefix = GeoTemCoMinifier_urlPrefix + 'lib/simile/ajax/';

if ( typeof window.SimileAjax == "undefined") {
	window.SimileAjax = {
		loadingScriptsCount : 0,
		error : null,
		params : {
			bundle : "true"
		}
	};

	SimileAjax.Platform = new Object();
	SimileAjax.includeCssFile = function(doc, url) {
		var link = doc.createElement("link");
		link.setAttribute("rel", "stylesheet");
		link.setAttribute("type", "text/css");
		link.setAttribute("href", url);
		doc.getElementsByTagName("head")[0].appendChild(link);
	};
	SimileAjax.urlPrefix = SimileAjax_urlPrefix;
}
