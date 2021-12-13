// Load verovio on demand
// it will queue all the calls so all the incipits
// are rendered when verovio is loaded and ready

var deferred_render_data = []
var verovio_loaded = false;

var worker = new Worker('/javascripts/verovio_worker.js');

const code2error = [
    "ERR_000_NO_ERROR",
    "ERR_001_EMPTY",
    "ERR_002_JSON_PARSE",
    "ERR_003_JSON_KEY",
    "ERR_004_KEY_SPACE",
    "ERR_005_CLEF_SPACE",
    "ERR_006_TIMESIG_SPACE",
    "ERR_007_REP_EMPTY",
    "ERR_008_REP_MARKER",
    "ERR_009_REP_OPEN",
    "ERR_010_REP_UNUSED",
    "ERR_011_REP_NO_FIGURE",
    "ERR_012_REP_NOT_BEGIN",
    "ERR_013_REP_NO_CONTENT",
    "ERR_014_REP_NO_BARLINE",
    "ERR_015_MREST_INVALID",
    "ERR_016_MREST_NUMBER",
    "ERR_017_TRILL_INVALID",
    "ERR_018_FERMATA_NESTED",
    "ERR_019_ACCID_NO_NOTE",
    "ERR_020_CHORD_NOTE_BEFORE",
    "ERR_021_CHORD_NOTE_AFTER",
    "ERR_022_BEAM_MENSURAL",
    "ERR_023_BEAM_NESTED",
    "ERR_024_BEAM_CLOSING",
    "ERR_025_BEAM_OPEN",
    "ERR_026_GRACE_NESTED",
    "ERR_027_GRACE_CLOSING",
    "ERR_028_GRACE_OPEN",
    "ERR_029_GRACE_UNRESOLVED",
    "ERR_030_GRACE_DURATION",
    "ERR_031_GRACE_NO_NOTE",
    "ERR_032_TUPLET_NESTED",
    "ERR_033_TUPLET_CLOSING",
    "ERR_034_TUPLET_NUM",
    "ERR_035_TUPLET_OPEN",
    "ERR_036_TUPLET_NUM_NUMBER",
    "ERR_037_TIE_PITCH",
    "ERR_038_TIE_OPEN",
    "ERR_039_TIE_NO_NOTE",
    "ERR_040_HIERARCHY_INVALID",
    "ERR_041_NESTING_INVALID",
    "ERR_042_CLEF_INCOMPLETE",
    "ERR_043_CLEF_INVALID_2ND",
    "ERR_044_CLEF_MENS",
    "ERR_045_CLEF_INVALID_3RD",
    "ERR_046_CLEF_INVALID",
    "ERR_047_TIMESIG_INCOMPLETE",
    "ERR_048_TIMESIG_INVALID",
    "ERR_049_TIMESIG_MENS",
    "ERR_050_INVALID_CHAR",
    "ERR_051_BARLINE",
    "ERR_052_DURATION",
    "ERR_053_DURATION_MENS3",
    "ERR_054_DURATION_MENS5",
    "ERR_055_KEYSIG_CHANGE",
    "ERR_056_TIMESIG_CHANGE",
    "ERR_057_MENSUR_CHANGE",
    "ERR_058_FERMATA_MREST"
 ];

function populateMessages(validation) {
	let highlights = [];
	let messages = [];

	let clefKeyWarnings = []

	if (validation.hasOwnProperty("clef")) {
		clefKeyWarnings.push(I18n.t("verovio.clef") + ": " + validation["clef"]["text"]);
	}
	if (validation.hasOwnProperty("keysig")) {
		clefKeyWarnings.push(I18n.t("verovio.keysig") + ": " + validation["keysig"]["text"]);
	}
	if (validation.hasOwnProperty("timesig")) {
		clefKeyWarnings.push(I18n.t("verovio.timesig") + ": " + validation["timesig"]["text"]);
	}

	if (validation.hasOwnProperty("data")) {
		let data = validation["data"];
		
		for (var i = 0; i < data.length; i++) {
			let i18n_text = "";
			
			if (data[i]["value"]) {
				i18n_text = I18n.t("verovio." + code2error[data[i]["code"]], {value: data[i]["value"]});
			} else {
				i18n_text = I18n.t("verovio." + code2error[data[i]["code"]]);
			}
			
			if (data[i]["column"] < 0) {
				messages.push(I18n.t("verovio.warning") + ": " + i18n_text);
			} else {
				messages.push(I18n.t("verovio.position") + " " +  data[i]["column"] + ": " + i18n_text);
			}

			let j = data[i]["column"];
			if (j > 0) highlights.push([j - 1, j]);
		}
	}

	let sortedMessages = messages.sort(function(a, b) {
		return a.localeCompare(b, undefined, {
			numeric: true,
			sensitivity: 'base'
		});
	});

	return [sortedMessages, clefKeyWarnings, highlights];
}

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
		let validation = event.data[2];

		let [messages, clefKeyWarnings, highlights] = populateMessages(validation);

		
		$("#" + target + "-textbox").highlightWithinTextarea('highlight', highlights);
		$("#" + target + "-clefKeyWarnings").html(clefKeyWarnings.join(" <br> "));
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