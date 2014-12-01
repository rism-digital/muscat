/*
	Attach autosize to textareas
	http://www.jacklmoore.com/autosize/

*/
(function(jQuery) {
	
	var self = null;
	jQuery.fn.textareaAutogrow = function() {
		var handler = function() {
			if (!this.textareaAutogrow) {
				this.textareaAutogrow = new jQuery.textareaAutogrow(this);
			}
		};
		
		if (jQuery.fn.on !== undefined) {
			return jQuery(document).on('focus', this.selector, handler);
		} else {
			return this.live('focus', handler);
		}
	};

	jQuery.textareaAutogrow = function (e) {
		_e = e;
		this.init(_e);
	};

	jQuery.textareaAutogrow.fn = jQuery.textareaAutogrow.prototype = {
		textareaAutogrow: '0.0.1'
	};

	jQuery.textareaAutogrow.fn.extend = jQuery.textareaAutogrow.extend = jQuery.extend;
	jQuery.textareaAutogrow.fn.extend({
		init: function(e) {
			te = $(e);
			te.autosize({append: false});
			te.trigger('autosize.resize');
		}
	});
	
	jQuery(document).ready(function() {
		jQuery(".autogrow").textareaAutogrow();
	});
	
	jQuery(document).ready(function(){
		jQuery('.autogrow').trigger('autosize.resize');
	});
	
})(jQuery);