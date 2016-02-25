/*

Handle the tag header button clicks
each function is attached on the base of the data-header-button value
Code in provided inline, in the future it can be moved out

used for _tag_header partial

*/

(function(jQuery) {
    
    // adjust the link when a help file is loaded in the editor
    // because we then want the interal link to load their content
    // through marc_editor_show_help (and not using #anchors)
    function adjust_editor_help_links() { 
        $('a[data-help-internal]').click(function(e){
            e.preventDefault();
            title = $(this).text();
            marc_editor_show_help($(this).data("help-internal"), title);
        });
    }
	
	function tag_header_toggle(elem) {
		tag_container = elem.parents(".tag_container");
		collapsable = tag_container.children(".tag_content_collapsable");
		
		// toggle
		collapsable.slideToggle(0);
	
		span = elem.children("span");
	
		if (collapsable.css("display") == "none") {
			span.removeClass('ui-icon-triangle-1-s');
			span.addClass('ui-icon-triangle-1-w');
		} else {
			span.removeClass('ui-icon-triangle-1-w');
			span.addClass('ui-icon-triangle-1-s');
		}
	}
	
	function tag_header_delete(button_id) {
		// FIXME dialog should not be hardcoded
		$('#dialog').html('<p>' + delete_field_confirm + '</p>');
		$("#dialog").dialog();
		$("#dialog").dialog( 'option', 'title', delete_msg );
		$("#dialog").dialog( 'option', 'width', 300);
		$("#dialog").dialog( 'option', 'buttons', {
			OK: function() {
				
				dt_id = button_id.parents(".tag_toplevel_container");
	
				dt_id.fadeOut('fast', function() {
                    tag_group = dt_id.parents(".tag_group");
					dt_id.remove();
                    update_empty_tag( tag_group );
				});
				
				$(this).dialog('close');
			},
			Cancel: function() { $(this).dialog('close');	}
			});
		$("#dialog").dialog('open');
	}
    
    function update_empty_tag(tag_group) {
        if ( tag_group.children(".marc_editor_tag_block").children().size() > 0 ) {
            tag_group.children(".tag_empty_container").hide();
        }
        else {
            tag_group.children(".tag_empty_container").show();
        }
    }
	
	// Create a new element when the tag_group already contains elements
	function tag_header_add(elem) {
		placeholder = elem.parents(".tag_group").children(".tag_placeholders_toplevel").children(".tag_placeholders");
		current_dt = elem.parents(".tag_toplevel_container");

		new_dt = placeholder.clone();
		new_dt.toggleClass('tag_placeholders tag_toplevel_container');
		new_dt.insertAfter(current_dt);
		new_dt.fadeIn('fast');
	}
    
	// Create a new element when the tag_group is empty. It is necessary
	// because in this case there is no tag_toplevel_container
	function tag_header_add_from_empty(elem) {
        // hide help if necessary
        elem.parents(".tag_container").children(".tag_help_collapsable").hide();
		placeholder = elem.parents(".tag_group").children(".tag_placeholders_toplevel").children(".tag_placeholders");
		parent_dl = elem.parents(".tag_group").children(".marc_editor_tag_block");

		new_dt = placeholder.clone();
		new_dt.toggleClass('tag_placeholders tag_toplevel_container');
		parent_dl.append(new_dt);
		new_dt.fadeIn('fast');
        update_empty_tag( elem.parents(".tag_group") );
	}

	function tag_header_edit(elem) {
		dt = elem.parents(".tag_toplevel_container");
	
		show_id = dt.find('.tag_container[data-function="edit"]');
		hide_id = dt.find('.tag_container[data-function="new"]');
		
	    $(hide_id).fadeOut('fast', function(){
	        $(show_id).fadeIn('fast');
	    });
	}
	
	function tag_header_new(elem) {
		dt = elem.parents(".tag_toplevel_container");

		var show_id = dt.find('.tag_container[data-function="new"]');
		var hide_id = dt.find('.tag_container[data-function="edit"]');

	    $(hide_id).fadeOut('fast', function(){
	        $(show_id).fadeIn('fast');
	    });
	}
    
	function tag_header_help(elem) {
        help_div = elem.parents(".tag_container").children(".tag_help_collapsable");
        if ( help_div.css('display') !== 'none') {
            help_div.fadeOut('fast');
            return;
        }
    	$.ajax({
    		success: function(data) {
                help_div.children(".help_content").html(data);
                adjust_editor_help_links();
                help_div.fadeIn('fast');
    		},
    		dataType: 'html',
    		timeout: 1000, 
    		type: 'get',
    		url: elem.data("help")
    	});
	}
	
	// Duplicate a whole group
	function tag_header_new_group(elem) {
		placeholder = elem.parents(".tab_panel").children(".group_placeholders_toplevel").children(".group_placeholders").children(".panel");
		toplevel_dl =  elem.parents(".tab_panel").children(".tag_group_container");
		
		new_group = placeholder.clone();
		dt = $("<dt />").append(new_group);
		dt.appendTo(toplevel_dl);
		dt.fadeIn('fast');
	}
	
	var self = null;
	jQuery.fn.tagHeaderButtons = function() {
		var handler = function() {
			if (!this.tagHeaderButtons) {
				this.tagHeaderButtons = new jQuery.tagHeaderButtons(this);
			}
		};
		
		if (jQuery.fn.on !== undefined) {
			return jQuery(document).on('mousedown', this.selector, handler);
		} else {
			return this.live('mousedown', handler);
		}
	};

	jQuery.tagHeaderButtons = function (e) {
		_e = e;
		this.init(_e);
	};

	jQuery.tagHeaderButtons.fn = jQuery.tagHeaderButtons.prototype = {
		tagHeaderButtons: '0.0.1'
	};

	jQuery.tagHeaderButtons.fn.extend = jQuery.tagHeaderButtons.extend = jQuery.extend;
	jQuery.tagHeaderButtons.fn.extend({
		init: function(e) {
			$(e).click(function(e) {
				e.preventDefault();
				
				if ($(this).data("header-button") == "toggle") {
					tag_header_toggle($(this));
				} else if ($(this).data("header-button") == "delete") {
					tag_header_delete($(this));
				} else if ($(this).data("header-button") == "add") {
					tag_header_add($(this));
				} else if ($(this).data("header-button") == "add-from-empty") {
					tag_header_add_from_empty($(this));
				} else if ($(this).data("header-button") == "new") {
					tag_header_new($(this));
				} else if ($(this).data("header-button") == "edit") {
					tag_header_edit($(this));
				} else if ($(this).data("header-button") == "help") {
					tag_header_help($(this));
				}else if ($(this).data("group-button") == "add") {
					tag_header_new_group($(this));
				}
                
				
			});
		}
	});
  
	jQuery(document).ready(function(){
		jQuery('.abutton').tagHeaderButtons();
	});
})(jQuery);

