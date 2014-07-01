var init_sidebar_actions = function () {
	$('a[data-scroll-target]').click(function(e){
		e.preventDefault();
		
		function show_tab_group(tname) {
			var current_item = null;
			var new_item = null;
		
			// Hide all the other panels
			$( ".tab_panel" ).each(function() {
				if ($(this).attr("name") != tname) {
				
					// If we have already an item shown, postpone
					// the hiding so we can cross fade it
					if ($(this).data("current-item") == true) {
						current_item = $(this);
					} else {
						$(this).hide();
					}
				
					$(this).removeData("current-item");
				} else {
					new_item = $(this);
					new_item.data("current-item", true);
				}
			})
		
			// If a group is already visible, cross fade
			if (current_item) {
			    current_item.fadeOut('fast', function(){
			        new_item.fadeIn('fast');
			    });
			} else {
				// No group already there
				new_item.fadeIn("fast");
			}
			//$.scrollTo($("[name=" + tname + "]"), 100, {offset: -10});
		} // function
		
		function show_all_tab_groups() {
			$( ".tab_panel" ).each(function() {
				$(this).fadeIn("fast");
				$(this).removeData("current-item");
			})
		} // function
		
		tname = $(this).data("scroll-target");
		
		if (tname == "show_all_groups") {
			show_all_tab_groups();
		} else {
			show_tab_group(tname);
		}

	});
};

$(document).ready(init_sidebar_actions);
// Fix for turbolinks: it will not call againg document.ready
$(document).on('page:load', init_sidebar_actions);