/*
* DataloaderConfig.js
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
 * @class DataloaderConfig
 * Dataloader Configuration File
 * @author Sebastian Kruse (skruse@mpiwg-berlin.mpg.de)
 */
function DataloaderConfig(options) {

	var dl = 'https://geobrowser.de.dariah.eu/';

	this.options = {
		staticKML : [
			// {header: "header label"},
			// {label: "Johann Wolfgang von Goethe", url:"http://.../goethe.kml" },
		{ header: "WebOPAC Göttingen" },
			{
				label: "Franz Kafka",
				url: dl + "data/kafka.kml"
			},
			{
				label: "Friedrich Schiller",
				url: dl + "data/schiller.kml"
			},
			{
				label: "Gotthold Ephraim Lessing",
				url: dl + "data/lessing.kml"
			},
			{
				label: "Heinrich Böll",
				url: dl + "data/boell.kml"
			},
			{
				label: "Heinrich Heine",
				url: dl + "data/heine.kml"
			},
			{
				label: "Johann Wolfgang von Goethe",
				url: dl + "data/goethe.kml"
			},
			{
				label: "William Shakespeare",
				url: dl + "data/shakespeare.kml"
			},
		{ header: "Static Flickr Data" },
			{
				label: "Tsunami",
				url: dl +"data/flickr/Tsunami.kml"
			},
			{
				label: "Volcano",
				url: dl +"data/flickr/Volcano.kml"
			},
			{
				label: "Earthquake",
				url: dl +"data/flickr/Earthquake.kml"
			},
			{
				label: "U2",
				url: dl +"data/flickr/U2.kml"
			},
			{
				label: "Muse", 
				url: dl +"data/flickr/Muse.kml"
			},
		{ header: "Political Data" },
			{
				label: "Guardian Afghanistan war logs",
				url: dl+"data/afghanevents1_type-category.kml"
			},
			{
				label: "Guardian Afghanistan IED attacks",
				url: dl+"data/explodedied_category.kml"
			},
			{
				label: "Armed Conflicts from 1945-2008",
				url: dl+"data/conflicts.kml"
			},
			{
				label: "Casualties of radical right-wing crimes",
				url: dl+"data/rechtegewalt.kml"
			},
		{ header:"Internet Movie Database" },
			{
				label: "Top 5000",
				url: dl+"data/imdb/imdb_best5000.kml"
			},
			{
				label: "Flop 5000",
				url: dl+"data/imdb/imdb_worst5000.kml"
			},
		{ header: "DBPedia Queries" },
			{
				label: "Museums",
				url: dl+"data/dbpedia/museum.kml"
			},
			{
				label: "Football World Cup Winners",
				url: dl+"data/dbpedia/WorldCupWinners.kml"
			},
			{
				label: "Football European Cup Winners",
				url: dl+"data/dbpedia/EuropeanCupWinners.kml"
			},
			{
				label: "Manchester United players",
				url: dl+"data/dbpedia/ManU.kml"
			},
			{
				label: "Chelsea FC players",
				url: dl+"data/dbpedia/Chelsea.kml"
			},
			{
				label: "FC Liverpool players",
				url: dl+"data/dbpedia/Liverpool.kml"
			},
			{
				label: "Real Madrid players",
				url: dl+"data/dbpedia/Real.kml"
			},
			{
				label: "FC Barcelona players",
				url: dl+"data/dbpedia/Barca.kml"
			},
			{
				label: "FC Bayern München players",
				url: dl+"data/dbpedia/FCBayern.kml"
			}
		]
	};

	if ( typeof options != 'undefined') {
		$.extend(this.options, options);
	}

};
