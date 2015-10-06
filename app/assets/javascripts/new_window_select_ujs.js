
var _nw_destination = null;
var _child = null;

function newWindowUpdateValue(id, label) {
	
	$("#wrapper").unblock();
	
	if (_nw_destination == null)
		return;
	
	// Get the autocomplete
	toplevel_li = _nw_destination.parents("li");
	ac = toplevel_li.find(".autocomplete_new_window");
	
	ac.val(label);
	
	_nw_destination.val(id);
	_nw_destination = null;
	_child = null
}

// This function is called when
// a user navigates away from the parent
function newWindowClose() {
	_child.close();
	_nw_destination = null;
	_child = null
}

function newWindowCancel() {
	$("#wrapper").unblock();
	_nw_destination = null;
	_child = null
}

function newWindowUnloaded() {
	
	// Someone changed page on the
	// child window or it was closed
	// wait a bit and see if it was
	// really closed
	
	setTimeout(function() { 
		if (_child && _child.closed) {
			newWindowCancel();
		}
	}, 700)
}


function newWindowIsSelect() {
	if (_nw_destination != null)
		return true;
	else
		return false;
}


// This extension binds to the button
// for each button that may be created
(function(jQuery) {
	
	var self = null;
	jQuery.fn.NewWindowSelect = function() {
		var handler = function() {
			if (!this.NewWindowSelect) {
				this.NewWindowSelect = new jQuery.NewWindowSelect(this);
			}
		};
		
		if (jQuery.fn.on !== undefined) {
			return jQuery(document).on('mousedown', this.selector, handler);
		} else {
			return this.live('mousedown', handler);
		}
	};

	jQuery.NewWindowSelect = function (e) {
		_e = e;
		this.init(_e);
	};

	jQuery.NewWindowSelect.fn = jQuery.NewWindowSelect.prototype = {
		NewWindowSelect: '0.0.1'
	};

	jQuery.NewWindowSelect.fn.extend = jQuery.NewWindowSelect.extend = jQuery.extend;
	jQuery.NewWindowSelect.fn.extend({
		init: function(e) {	
			$(e).click(function(e, data) {
				e.preventDefault();
				
				$("#wrapper").block({message: ""});
				
				toplevel_li = $(this).parents(".tag_container");
				_nw_destination = toplevel_li.find(".autocomplete_target")
				
				controller = $(this).data("controller");
				
				// Open up the new window
				_child = window.open('/admin/' + controller + '?select=true', null, "location=no");
				
			});
		}
	});
	
	jQuery(document).ready(function() {
		jQuery(".new_window_select").NewWindowSelect();
	});
	
})(jQuery);

// Add a function to the doc ready
// to bind the various "select" buttons
// in the child window
var add_window_select_actions = function () {
	
	// Is this window opened from another window?
	if (window.opener != null) {
		// Is this called from the selection code?
		if (window.opener.newWindowIsSelect()) {
			// Set the before unload so it cancels
			// the action if the window is closed
			window.onunload = function(e) {
				window.opener.newWindowUnloaded();
			}
		}
	}
	
	$('a[data-marc-editor-select]').click(function(e) {
		e.preventDefault();
		
		id = $(this).data("marc-editor-select");
		label = $(this).data("marc-editor-label");
		
		window.opener.newWindowUpdateValue(id, label);
		window.close();
	});
	
	$('a[data-marc-editor-cancel]').click(function(e) {
		e.preventDefault();
				
		window.opener.newWindowCancel();
		window.close();
	});
}

$(document).ready(add_window_select_actions);
// Fix for turbolinks: it will not call againg document.ready
$(document).on('page:load', add_window_select_actions);