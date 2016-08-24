/*
	Select and search an element on a new window
	This is the generic non-marc version, to use outside the marc editor
*/

var _nw_destination = null;
var _child = null;
var _object_model = null;

function deselectSession() {
	$.ajax({
		success: function(data) {},
		data: {
			deselect: true, 
		},
		dataType: 'script',
		timeout: 20000,
		type: 'get',
		url: '/admin/session/deselect', 
	});
}

function newWindowUpdateValue(id, label) {
	
	deselectSession();
	$("#wrapper").unblock();
	
	window.location.href = _nw_destination + "?object_id=" + id + "&object_model=" + _object_model;
	
	_child = null;
}

// This function is called when
// a user navigates away from the parent
function newWindowClose() {

	deselectSession();
	_child.close();
	_nw_destination = null;
	_child = null;
	_object_model = null;
}

function newWindowCancel() {

	deselectSession();
	$("#wrapper").unblock();
	_nw_destination = null;
	_child = null;
	_object_model = null;
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
	if (_child != null)
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
				var controller = $(this).data("controller");
				var model = $(this).data("model");
				var id = $(this).data("id");
				_nw_destination = "/admin/" + model + "/" + id + "/add_item";
				_object_model = $(this).data("object");
				
				// Open up the new window
				_child = window.open('/admin/' + controller + '?select=true', null, "location=no");
				
			});
		}
	});
	
	jQuery(document).ready(function() {
		jQuery("#new_window_select_nomarc").NewWindowSelect();
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