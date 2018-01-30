/*
* Dropdown.js
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
 * @class Publisher
 * Publish/Subscribe mechanism
 * @author Stefan Jänicke (stjaenicke@informatik.uni-leipzig.de)
 * @release 1.0
 * @release date: 2012-07-27
 * @version date: 2012-07-27
 */
if ( typeof Publisher == 'undefined') {

	Publisher = function() {

		var topics = [];

		this.Get = function(topic) {
			var value = topics[topic];
			if (!value || !(value instanceof Array)) {
				value = topics[topic] = [];
			}
			return value;
		};

		this.Publish = function(topic, data, publisher) {
			var subscribers = this.Get(topic);
			for (var i = 0; i < subscribers.length; i++) {
				if (publisher == null || subscribers[i].client != publisher) {
					subscribers[i].callback(data);
				}
			}
		};

		this.Subscribe = function(topic, subscriber, callback) {
			var subscribers = this.Get(topic);
			subscribers.push({
				client : subscriber,
				callback : callback
			});
		};

		this.Unsubscribe = function(topic, unsubscriber) {
			var subscribers = this.Get(topic);
			for (var i = 0; i < subscribers.length; i++) {
				if (subscribers[i].client == unsubscriber) {
					subscribers.splice(i, 1);
					return;
				}
			}
		};

		return this;

	}();

}
