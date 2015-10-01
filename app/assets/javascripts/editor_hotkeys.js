/*
	Setup the editor hotkeys
	We need to do it this way because inputs are created on the fly
	It attaches to the .marc_editor_hotkey class

*/
(function(jQuery) {
	
	var self = null;
	jQuery.fn.editorHotkeys = function() {
		var handler = function() {
			if (!this.editorHotkeys) {
				this.editorHotkeys = new jQuery.editorHotkeys(this);
			}
		};
		
		if (jQuery.fn.on !== undefined) {
			return jQuery(document).on('focus', this.selector, handler);
		} else {
			return this.live('focus', handler);
		}
	};

	jQuery.editorHotkeys = function (e) {
		_e = e;
		this.init(_e);
	};

	jQuery.editorHotkeys.fn = jQuery.editorHotkeys.prototype = {
		editorHotkeys: '0.0.1'
	};

	jQuery.editorHotkeys.fn.extend = jQuery.editorHotkeys.extend = jQuery.extend;
	jQuery.editorHotkeys.fn.extend({
		init: function(e) {
			
			$(e).on('keydown', null, 'alt+ctrl+s', function(){
				marc_editor_send_form(false);
			});

			$(e).on('keydown', null, 'alt+ctrl+p', function(){
				marc_editor_show_preview();
			});
	
			$(e).on('keydown', null, 'alt+ctrl+n', function(){
				window.location.href = "/" +  marc_editor_get_model() + "/new";
			});
		}
	});
	
	jQuery(document).ready(function() {
		jQuery(".marc_editor_hotkey").editorHotkeys();
	});
	
})(jQuery);