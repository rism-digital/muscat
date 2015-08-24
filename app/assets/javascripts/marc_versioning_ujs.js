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
				model = $(this).data("model")
				marc_editor_version(version, 'marc_editor_preview', model);
			});
		}
	});
	
	jQuery(document).ready(function() {
		jQuery(".marc_versioning").marcVersioning();
	});
	
})(jQuery);