/*
	Unobtrusive Javascript for Relator Code cascade <select>

	It extends jQuery so each top_cascade_select gets automatic binding
	The tag structure should be:

	<div class="tag_group">
		...
		<div data-select-code-list=[list data]>/div>
		...
		<select class="top_cascade_select"></select>
		<select class="bottom_cascade_select"></select>
		<input type="hidden" class="cascade_select_target">
	</div>

	data-select-code-list need not to be at the same level, but should be
	child if tag_group

	data-select-code-list is implemented in _tag_list_header_relator_codes
	
	Used for _subfield_relator_codes_700
*/

(function(jQuery) {
	var self = null;
	jQuery.fn.relatorCodesCascade = function() {
		var handler = function() {
			if (!this.relatorCodesCascade) {
				this.relatorCodesCascade = new jQuery.relatorCodesCascade(this);
			}
		};
		
		if (jQuery.fn.on !== undefined) {
			return jQuery(document).on('focus', this.selector, handler);
		} else {
			return this.live('focus', handler);
		}
	};

	jQuery.relatorCodesCascade = function (e) {
		_e = e;
		this.init(_e);
	};

	jQuery.relatorCodesCascade.fn = jQuery.relatorCodesCascade.prototype = {
		relatorCodesCascade: '0.0.1'
	};

	jQuery.relatorCodesCascade.fn.extend = jQuery.relatorCodesCascade.extend = jQuery.extend;
	jQuery.relatorCodesCascade.fn.extend({
		init: function(e) {
			parent_select = $(e);
	
			data = parent_select.parents(".tag_group").children("[data-select-code-list]");
	
			child_select = parent_select.parent().children(".bottom_cascade_select")
			$(child_select).cascade(parent_select, {					
				list: data.data("select-code-list"),
				template: function(item) {
					return "<option value='" + item.Value + "'>" + item.Text + "</option>";
				},
				match: function(selectedValue) {
					return this.When == selectedValue
				}
			});
	
			child_select.change(function(e, data){
				hidden = parent_select.parent().children(".cascade_select_target");
				hidden.val(this.value)

			});
	
		}
	});
  
	jQuery(document).ready(function(){
		jQuery('.top_cascade_select').relatorCodesCascade();
	});
})(jQuery);