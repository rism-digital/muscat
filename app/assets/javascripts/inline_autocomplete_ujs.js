/*
	Attach simple autocmplete for items what pass their
	value from BasicFormOptions. Not to be confused with the
	autocomplete for authority files which has more complex
	data sources.

	Here we look for a data-autocomplete-values under the same parent
	which contains the JSON array data

*/
(function(jQuery) {
	
	var self = null;
	jQuery.fn.inlineAutocomplete = function() {
		var handler = function() {
			if (!this.inlineAutocomplete) {
				this.inlineAutocomplete = new jQuery.inlineAutocomplete(this);
			}
		};
		
		if (!this.inlineAutocomplete) {
			this.inlineAutocomplete = new jQuery.inlineAutocomplete(this);
		}
		
		if (jQuery.fn.on !== undefined) {
			return jQuery(document).on('focus', ".inline-autocomplete", handler);
		} else {
			return this.live('load', handler);
		}
	};

	jQuery.inlineAutocomplete = function (e) {
		_e = e;
		this.init(_e);
	};

	jQuery.inlineAutocomplete.fn = jQuery.inlineAutocomplete.prototype = {
		inlineAutocomplete: '0.0.1'
	};

	jQuery.inlineAutocomplete.fn.extend = jQuery.inlineAutocomplete.extend = jQuery.extend;
	jQuery.inlineAutocomplete.fn.extend({
		init: function(e) {
			elem = $(e);
			
			data_div = elem.parent().children("[data-autocomplete-values]");
			// if it is an array it is the values to autocomplete
			// or it can be an URL to be used from the backend
			var valuesArrayOrURL = data_div.data("autocomplete-values");
			
			$(elem).autocomplete(
					{
						source: valuesArrayOrURL,
						delay:10,
						minChars:0,
						matchSubset:0,
						autoFill:true,
						maxItemsToShow:10,
					}
				);
			
		}
	});
	
	jQuery(document).ready(function() {
		jQuery(".inline-autocomplete").inlineAutocomplete();
	});
	
})(jQuery);