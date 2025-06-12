/*
	Attach to the PAE input boxes to create the PAE preview

*/
(function(jQuery) {
	
	var self = null;
	jQuery.fn.edtfSubfieldRenderer = function() {
		var handler = function() {
			if (!this.edtfSubfieldRenderer) {
				this.edtfSubfieldRenderer = new jQuery.edtfSubfieldRenderer(this);
			}
		};
		
		if (jQuery.fn.on !== undefined) {
            jQuery(document).on('update', "#input-edtf", handler);
			return jQuery(document).on('keydown', "#input-edtf", handler);
		} else {
			return this.live('keydown', handler);
		}
	};

	jQuery.edtfSubfieldRenderer = function (e) {
		_e = e;
		this.init(_e);
	};

	jQuery.edtfSubfieldRenderer.fn = jQuery.edtfSubfieldRenderer.prototype = {
		edtfSubfieldRenderer: '0.0.1'
	};

	jQuery.edtfSubfieldRenderer.fn.extend = jQuery.edtfSubfieldRenderer.extend = jQuery.extend;
	jQuery.edtfSubfieldRenderer.fn.extend({
		init: function(object) {

			function update_edtf(obj) {
				try {
					const parsed_date = edtf($(obj).val());
					//const formatted = edtf_format(parsed_date, 'en-US')
					$("#edtf-message").html("EDTF Date parser is happy! ☺︎");
					$("#edtf-error").empty();
				} catch (err) {
					const first_3_lines = err.message.split(/\r?\n/).slice(0, 4).join('\n');
					$("#edtf-message").html("It was not possible to parse the EDTF date ☹");
					$("#edtf-error").html($('<pre>').text(first_3_lines) );
				}
			}

			// Atach to the keyup event
			$(object).keyup(function(e) {
				e.preventDefault();
				update_edtf(this);
			});
			
			// Update on first load
			update_edtf(object);
		},
	});
	
	jQuery(document).ready(function() {
		jQuery("#input-edtf").edtfSubfieldRenderer();
		jQuery("#input-edtf").trigger('update');
		$()
		
	});
	
})(jQuery);