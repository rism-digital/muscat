// Load verovio on demand
// it will queue all the calls so all the incipits
// are rendered when verovio is loaded and ready

var vrvToolkit = null;

var deferred_render_data = []
var verovio_loading = false;

function finalize_verovio () {
	verovio_loading = false
	vrvToolkit = new verovio.toolkit();
	
	for (var i = 0; i < deferred_render_data.length; i++) {
	    data = deferred_render_data[i];
		render_music(data.music, data.format, data.target, data.width);
	}
}

function load_verovio() {
	if (verovio_loading == true) {
		return;
	}
	
	verovio_loading = true;
	
	var element = document.createElement("script");
	element.src = "/javascripts/verovio-toolkit.js";
	document.body.appendChild(element);
	
    element.onreadystagechange = finalize_verovio;
    element.onload = finalize_verovio;

}

// This is the helper function to call to render 
// an incipit into a target div. It will do the preloading
// in the background
function render_music( music, format, target, width ) {	
	width = typeof width !== 'undefined' ? width : 720;
	
	if (vrvToolkit == null) {
		deferred_render_data.push({
			music: music, 
			format: format, 
			target: target, 
			width: width});
			
		load_verovio();
		return;
	}
	
	options = JSON.stringify({
				inputFormat: 'pae',
				pageWidth: width / 0.4,
				spacingStaff: 1,
				border: 10,
				scale: 40,
				ignoreLayout: 0,
				adjustPageHeight: 1
			});
			
	vrvToolkit.setOptions( options );
	vrvToolkit.loadData(music + "\n" );
	svg = vrvToolkit.renderPage(1, "");
	
	$(target).html(svg);
};