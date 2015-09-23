var init_sidebar_actions = function () {
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
			
			if (action == "save") {
				marc_editor_send_form('marc_editor_panel', marc_editor_get_model());
			} else if (action == "cancel") {
				marc_editor_redirect(marc_editor_get_model());
			} else if (action == "exit") {
				marc_editor_send_form('marc_editor_panel', marc_editor_get_model(), true);
			}
			
		}
		
		tname = $(this).data("scroll-target"); // type of action
		panel = $(this).data("panel"); // toplevel panel
		
		if (tname == "show_toplevel") {
			// Show a specific toplevel panel
			show_toplevel(panel);
		} else if (tname == "action") {
			do_actions($(this).data("action"));
		} else if (tname == "show_preview") {
			// the preview panel requires AJAX to get the data
			// so we defer action to this function
			// if it succeeds it will display the correct panel
			marc_editor_show_hide_preview();
		} else {
			// This is for showing/hiding subtabs in marc
			show_tab_group(tname, panel);
		}
				
		window.scrollTo(0, 0);
		
	});
};

$(document).ready(init_sidebar_actions);
// Fix for turbolinks: it will not call againg document.ready
$(document).on('page:load', init_sidebar_actions);