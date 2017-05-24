var init_sidebar_actions = function () {
    
    $('a[data-save-form]').click(function(e) {
        form = $("#" + $(this).data("save-form"));
        
        // Triggers work as for marc editor:
        // extract them, and pass them to the request form
        triggers = marc_editor_get_triggers();
        //Append them to the form as a hidden value
        // this way we can use the same code we use in the marc ed
        var $input = $('<input type="hidden" name="triggers" />')
        $input.val(JSON.stringify(triggers));
        form.append($input);
        
        form.submit();
    });
    
	$('a[data-scroll-target]').click(function(e){
		e.preventDefault();
		
		function show_toplevel(panel) {
			// Show all the subpanels, if any
			marc_editor_show_all_subpanels();
			
			// Show the selected subpaned
			// and toplevel panel
			marc_editor_show_panel(panel);
		} // function
		
		// Defer to the marc_editor
		// for the save, cancel and
		// save and exit actions
		function do_actions(action) {
			var redirect = false;
			if (action == "save") {
				// ok it is redundand
				// save will not redirect to index
				redirect = false;
			} else if (action == "exit") {
				// Save and exit will redirect
				redirect = true;
			}
			marc_editor_send_form(redirect);
		}
		
		tname = $(this).data("scroll-target"); // type of action
		panel = $(this).data("panel"); // toplevel panel
		help = $(this).data("help"); // the help file to load
		
		if (tname == "show_toplevel") {
			// Show a specific toplevel panel
			show_toplevel(panel);
			// Save the full view
			marc_editor_set_last_tab("full", "full");
		} else if (tname == "action") {
			do_actions($(this).data("action"));
		} else if (tname == "show_preview") {
			// the preview panel requires AJAX to get the data so we defer action to this function
			// if it succeeds it will display the marc_editor_preview panel
			marc_editor_show_preview();
			$("#show_preview_li").hide();
			$("#hide_preview_li").show();
		} else if (tname == "hide_preview") {
			show_toplevel(panel);
			marc_editor_set_last_tab("full", "full");
			$("#hide_preview_li").hide();
			$("#show_preview_li").show();
		} else if (tname == "show_help") {
			// the preview panel requires AJAX to get the data so we defer action to this function
			// if it succeeds it will display the marc_editor_help panel
			marc_editor_show_help(help, $(this).data("help-title"));
		} else {
			// This is for showing/hiding subtabs in marc
			marc_editor_set_last_tab(tname, panel);
			marc_editor_show_tab_in_panel(tname, panel);
		}
				
		window.scrollTo(0, 0);
		
	});
    
	$('a[data-toggle-help-sections]').click(function(e){
        e.preventDefault();
        $(this).parents(".guidelines_chapter").children(".guidelines_sections").toggle();
        $(this).toggleClass("left down");
    });
};

$(document).ready(init_sidebar_actions);
// Fix for turbolinks: it will not call againg document.ready
$(document).on('page:load', init_sidebar_actions);
