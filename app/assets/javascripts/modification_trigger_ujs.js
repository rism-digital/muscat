(function(jQuery) {
	
	var self = null;
	jQuery.fn.modifiedTrigger = function() {
		var handler = function() {
			if (!this.modifiedTrigger) {
				this.modifiedTrigger = new jQuery.modifiedTrigger(this);
			}
		};
		
		if (!this.modifiedTrigger) {
			this.modifiedTrigger = new jQuery.modifiedTrigger(this);
		}
		
		if (jQuery.fn.on !== undefined) {
			return jQuery(document).on('keydown', this.selector, handler);
		} else {
			return this.live('keydown', handler);
		}
	};

	jQuery.modifiedTrigger = function (e) {
		_e = e;
		this.init(_e);
	};

	jQuery.modifiedTrigger.fn = jQuery.modifiedTrigger.prototype = {
		modifiedTrigger: '0.0.1'
	};

	jQuery.modifiedTrigger.fn.extend = jQuery.modifiedTrigger.extend = jQuery.extend;
	jQuery.modifiedTrigger.fn.extend({
		init: function(e) {
			$(e).keydown(function(e) {
				// in this case ALSO forward the default!
				// we do not want to kill all ketdowns
				//e.preventDefault();
				
				if (!$(this).data("triggered")) {
					triggers = $(this).data("trigger");
					$(this).data("triggered", triggers);
				}
				
			});
		}
	});
	
	jQuery(document).ready(function() {
		jQuery("[data-trigger]").modifiedTrigger();
	});
	
})(jQuery);