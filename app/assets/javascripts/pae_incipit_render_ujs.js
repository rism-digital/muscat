/*
	Attach to the PAE input boxes to create the PAE preview

*/
(function(jQuery) {
	
	var self = null;
	jQuery.fn.paeIncipitRender = function() {
		var handler = function() {
			if (!this.paeIncipitRender) {
				this.paeIncipitRender = new jQuery.paeIncipitRender(this);
			}
		};
		
		if (jQuery.fn.on !== undefined) {
			jQuery(document).on('update', ".pae_input", handler);
			return jQuery(document).on('keydown', ".pae_input", handler);
		} else {
			return this.live('keydown', handler);
		}
	};

	jQuery.paeIncipitRender = function (e) {
		_e = e;
		this.init(_e);
	};

	jQuery.paeIncipitRender.fn = jQuery.paeIncipitRender.prototype = {
		paeIncipitRender: '0.0.1'
	};

	jQuery.paeIncipitRender.fn.extend = jQuery.paeIncipitRender.extend = jQuery.extend;
	jQuery.paeIncipitRender.fn.extend({
		init: function(object) {

			$(object).highlightWithinTextarea({
				highlight: []
			});

			// Atach to the keyup event
			$(object).keyup(function(e) {
				e.preventDefault();
				display_music(this)
			});
			
			// Handle the button
			$('a[data-pae-button]').off().on('click', function(e) {
				e.preventDefault();

				// Since this is the button, we need to get
				// the width of the actual input box
				let box_name = $(this).data("pae-box");
				let box = $("#" + box_name);

				display_music(this, box.width());
			});
			
			function display_music(obj, width = 0) {
				var grid = $(obj).parents(".tag_grid");
				var placeholder = $(obj).parents(".tag_placeholders");
				

				// If the parent is a "placeholder" it means this 
				// PAE box is not displayed.
				if (placeholder[0] !== undefined) {
					return;
				}
			
				var pae_key = $(".subfield_entry[data-subfield='n']", grid).val();
				var pae_time = $(".subfield_entry[data-subfield='o']", grid).val();
				var pae_clef = $(".subfield_entry[data-subfield='g']", grid).val();
				var pae_data = $(".subfield_entry[data-subfield='p']", grid).val(); //$(obj).val();
				if (width == 0)
					width = $(obj).width(); // Get the parent textbox with so the image is the same
			
				var target_div = $('.pae_incipit_target', grid);

				marc_editor_incipit(
					pae_clef,
					pae_key,
					pae_time,
					pae_data,
					target_div, 
					width);
    		
					$(target_div).parents('table').show();
					$(target_div).show();
			}
			
			// Update on first load
			display_music(object);
		},
	});
	
	jQuery(document).ready(function() {
		jQuery(".pae_input").paeIncipitRender();
		jQuery(".pae_input").trigger('update');
		$()
		
	});
	
})(jQuery);