var init_sidebar_actions = function () {
    
    $('a[data-save-form]').click(function(e) {
        form = $("#" + $(this).data("save-form"));
        form.submit();
    });
    
	$('a[data-scroll-target]').click(function(e){
		e.preventDefault();
		
		function show_tab_group(tname, panel) {
			var current_item = null;
			var new_item = null;
		
			// Hide all the other panels
			$( ".tab_panel" ).each(function() {
				if ($(this).attr("name") != tname) {
					$(this).hide();
				} else {
					$(this).show();
				}
			});
			
			marc_editor_show_panel(panel)
			//$.scrollTo($("[name=" + tname + "]"), 100, {offset: -10});
		} // function
		
		function show_toplevel(panel) {
			
			// Show all the subpanels, if any
			$( ".tab_panel" ).each(function() {
				$(this).show();
				$(this).removeData("current-item");
			})
			
			marc_editor_show_panel(panel)
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
		} else if (tname == "action") {
			do_actions($(this).data("action"));
		} else if (tname == "show_preview") {
			// the preview panel requires AJAX to get the data so we defer action to this function
			// if it succeeds it will display the marc_editor_preview panel
			marc_editor_show_preview();
		} else if (tname == "show_help") {
			// the preview panel requires AJAX to get the data so we defer action to this function
			// if it succeeds it will display the marc_editor_help panel
			marc_editor_show_help(help, $(this).data("help-title"));
		} else {
			// This is for showing/hiding subtabs in marc
			show_tab_group(tname, panel);
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