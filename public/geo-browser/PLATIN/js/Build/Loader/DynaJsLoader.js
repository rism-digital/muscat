/*
* DynaJsLoader.js
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
 * Dynamic Script Loader for GeoTemCo
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
function DynaJsLoader() {

	this.checkInterval = 20;
	this.loadAttempts = 2000;

	this.loadScripts = function(scripts, callback) {

		if (scripts.length > 0) {
			this.scriptStack = scripts;
			this.scriptIndex = 0;
			this.loadScript(callback);
		}

	};

	this.loadScript = function(callback) {

		var loader = this;
		if (this.scriptIndex < this.scriptStack.length) {

			var scriptEmbedded = false, scriptLoaded = false, iter = 0;
			var scriptData = this.scriptStack[this.scriptIndex];
			this.scriptIndex++;
			var testFunction = scriptData.test;
			var test = function() {
				scriptEmbedded = true;
				if (!testFunction || typeof (eval(testFunction)) === 'function') {
					scriptLoaded = true;
				} else {
					setTimeout(function() {
						test();
					}), loader.checkInterval
				}
			}
			var head = document.getElementsByTagName('head')[0];
			var script = document.createElement('script');
			script.type = 'text/javascript';
			script.src = scriptData.url;

			script.onload = test;
			script.onreadystatechange = function() {
				if (this.readyState == 'complete') {
					test();
				}
			}

			head.appendChild(script);

			var checkStatus = function() {
				if (scriptEmbedded && scriptLoaded) {
					loader.loadScript(callback);
					if ( typeof console != 'undefined') {
						console.log(scriptData.url + " loaded in " + (iter * loader.checkInterval) + " ms");
					}
				} else {
					iter++;
					if (iter > loader.loadAttempts) {
						if ( typeof console != 'undefined') {
							console.log("MapTimeView not loaded: Not able to load " + scriptData.url + "!");
							Publisher.Publish('StifReady', null);
						}
						return;
					}
					setTimeout(function() {
						checkStatus();
					}), loader.checkInterval
				}
			}
			checkStatus();

		} else if (callback) {
			callback();
		}

	};

};
