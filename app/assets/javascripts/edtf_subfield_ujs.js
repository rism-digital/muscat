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
				let parsed_date;
				let default_locale = "en-US";

				const formats = {
					weekday: "long",
					year: "numeric",
					month: "long",
					day: "numeric",
				}

				/*
				The various localizations are lacking
				so for the moment we default to the eng one
				const locales = {
					en: "en-US",
					it: "it-IT",
					de: "de-DE",
					fr: "fr-FR",
					es: "es-ES"
				};

				if ((I18n.locale in locales))
					default_locale = locales[I18n.locale]
				*/

				try {
					parsed_date = edtf($(obj).val());
				} catch (err) {
					const first_3_lines = err.message.split(/\r?\n/).slice(0, 4).join('\n');
					$("#edtf-message").html("It was not possible to parse the EDTF date ☹");
					$("#edtf-error").html($('<pre>').text(first_3_lines) );
					return;
				}

				let formatted = parsed_date

				try {
					formatted = edtf_format(parsed_date, default_locale, formats)
				} catch (err) {
					//console.log(err)
				}
				
				//const formatted = edtf_format(parsed_date, 'en-US')
				$("#edtf-message").html("Formatted date: " + formatted);
				$("#edtf-error").empty();

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