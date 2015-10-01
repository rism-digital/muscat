/*
	UJS versioning links 

*/
(function(jQuery) {
	
	var self = null;
	jQuery.fn.marcVersioning = function() {
		var handler = function() {
			if (!this.marcVersioning) {
				this.marcVersioning = new jQuery.marcVersioning(this);
			}
		};
		
		if (jQuery.fn.on !== undefined) {
			return jQuery(document).on('mousedown', this.selector, handler);
		} else {
			return this.live('mousedown', handler);
		}
	};

	jQuery.marcVersioning = function (e) {
		_e = e;
		this.init(_e);
	};

	jQuery.marcVersioning.fn = jQuery.marcVersioning.prototype = {
		marcVersioning: '0.0.1'
	};

	jQuery.marcVersioning.fn.extend = jQuery.marcVersioning.extend = jQuery.extend;
	jQuery.marcVersioning.fn.extend({
		init: function(e) {
			// Atach to the click event
			$(e).click(function(e) {
				e.preventDefault();
				version = $(this).data("version");
				action = $(this).data("action");
				if (action == "preview") {
					marc_editor_version_view(version);
				}
				else if (action == "diff") {
					marc_editor_version_diff(version);
				}
			});
		}
	});
	
	jQuery(document).ready(function() {
		jQuery(".marc_versioning").marcVersioning();
	});
	
})(jQuery);


var init_modification_bars = function () {
	$('div[data-version-modification]').each(function() {
		percent = $(this).data("version-modification");
		$(this).css('width', (100 - percent) + '%');
	});
};

$(document).ready(init_modification_bars);
// Fix for turbolinks: it will not call againg document.ready
$(document).on('page:load', init_modification_bars);