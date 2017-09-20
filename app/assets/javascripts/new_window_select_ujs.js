
var _nw_destination = null;
var _child = null;
var _interval = null;

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
	
	if (_nw_destination == null)
		return;
	
	var field = _nw_destination.data("field")
	
	// Get the autocomplete
	toplevel_li = _nw_destination.parents("li");
	ac = toplevel_li.find(".autocomplete_new_window");
	
	_nw_destination.addClass("serialize_marc");
	var element_class = marc_editor_validate_className(_nw_destination.data("tag"), _nw_destination.data("subfield"));
	_nw_destination.addClass(element_class);
	// Write the data
	if (_nw_destination.data("has-links-to") == false) {
		// Normal autocomplete writes the ID of the linked resource in the hidden
		_nw_destination.val(id);
	} else {
		// links-to need the TEXT not the id
		_nw_destination.val(label);
	}
	_nw_destination.data("status", "selected");
	
	ac.removeClass("serialize_marc");
	ac.removeClass("new_autocomplete");
	
	// Remove the checkbox
	var check_tr = toplevel_li.find(".checkbox_confirmation")
	check_tr.fadeOut("fast");
	
	var check = toplevel_li.find(".creation_checkbox")
	check.data("check", false)
	
	// set the value of the AC by hand
	ac.val(label);
	
	_nw_destination = null;
	_child = null
}

// This function is called when
// a user navigates away from the parent
function newWindowClose() {

	deselectSession();
	_child.close();
	_nw_destination = null;
	_child = null;
}

function newWindowCancel() {

	deselectSession();
	$("#wrapper").unblock();
	_nw_destination = null;
	_child = null;
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
				
				var toplevel_li = $(this).parents(".tag_container");
				// This is always the hidden field
				_nw_destination = toplevel_li.find(".autocomplete_target")
				
				var controller = $(this).data("controller");
				var new_window_field = $(this).data("new-window-field");
				var selection_record_type = $(this).data("selection-record-type")
				
				var search = "";
				if (new_window_field) {
					var ac = toplevel_li.find(".autocomplete_new_window");
					var value = ac.val();
					if (value) {
						search = "&q[" + new_window_field + "]=" + value;
					}
				}

				// In selection mode, for sources, we can force the record type
				if (selection_record_type) {
					search += "&q[record_type_with_integer]=record_type:" + selection_record_type;
				}
				// Open up the new window
				_child = window.open('/admin/' + controller + '?select=true' + encodeURI(search), null, "location=no");
				
				_interval = setInterval(function() {
					if (_child && _child.closed) {
						clearInterval(_interval);
						newWindowCancel();
					}
				}, 2000)
				
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

if (window.opener != null && window.opener.$(".new_window_select").length > 0) {
	$(document).ready(add_window_select_actions);
	// Fix for turbolinks: it will not call againg document.ready
	$(document).on('page:load', add_window_select_actions);
}