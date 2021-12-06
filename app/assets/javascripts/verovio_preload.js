// Load verovio on demand
// it will queue all the calls so all the incipits
// are rendered when verovio is loaded and ready

var deferred_render_data = []
var verovio_loaded = false;

var worker = new Worker('/javascripts/verovio_worker.js');
worker.onmessage = function(event) {
	let messageType = event.data[0];

	if (messageType == "loaded") {
		finalize_verovio();
	} else if (messageType == "renderMusic-ok" || messageType == "renderMEI-ok") {
		let target = event.data[1];
		let svg = event.data[2];

		$("#" + target).html(svg);

	} else if (messageType == "validatePAE-ok") {
		let target = event.data[1];
		let messages = event.data[2];
		let highlights = event.data[3];

		
		$("#" + target + "-textbox").highlightWithinTextarea('highlight', highlights);
		$("#" + target + "-messages").html(messages.join(" <br> "));
	}
};

function finalize_verovio () {
	verovio_loaded = true;
	
	for (var i = 0; i < deferred_render_data.length; i++) {
	    data = deferred_render_data[i];
		render_music(data.music, data.format, data.target, data.width);
	}
}

// This is the helper function to call to render 
// an incipit into a target div. It will do the preloading
// in the background
function render_music(music, format, target, width) {	
	var width = typeof width !== 'undefined' ? width : 720;
	
	if (verovio_loaded == false) {
		deferred_render_data.push({
			music: music, 
			format: format, 
			target: target, 
			width: width});
			
		return;
	}

	if (format === "pae") {
		var options = {
			inputFrom: 'pae',
			pageMarginTop: 40,
			pageMarginBottom: 60,
			pageMarginLeft: 20,
			pageMarginRight: 20,
			pageWidth: width / 0.4,
			spacingStaff: 1,
			scale: 40,
			adjustPageHeight: 1
		};
		
		this.worker.postMessage(["validatePAE", $(target).attr("id"), {options: options, music: music}])
		this.worker.postMessage(["renderMusic", $(target).attr("id"), {options: options, music: music}])

	} else {

		var options = {
			inputFrom: 'mei',
			pageWidth: width / 0.4,
			spacingStaff: 1,
			scale: 40,
			adjustPageHeight: 1
		};
		
		/* Load the file using HTTP GET */
		$.get(music, function( data ) {
			worker.postMessage(["renderMEI", $(target).attr("id"), {options: options, music: data}])
		}, 'text');
	}

};