////////////////////////////////////////////////////////////////////
// Init the tags called from the edit_wide.rhtml partial
////////////////////////////////////////////////////////////////////
marc_editor_form_changed = false;

function marc_editor_init_tags( id ) {
	
	// Set event hooks
	// avoid user to accidently leave the page when the form was modify 
	// will ask for a confirmation
	window.onbeforeunload = marc_editor_discard_changes_leaving;
	window.onunload = marc_editor_cleanp;
	
	$(".sortable").sortable();


	marc_editor_form_changed = false;
	$(id).dirtyFields({
		trimText:true,
		fieldChangeCallback: function(originalValue, isDirty) {
			marc_editor_form_changed = true;
		}
	});	

	/* Bind to the global railsAutocomplete. event, thrown when someone selects
	   from an autocomplete field. It is a delegated method so dynamically added
	   forms can handle it
	*/
	$("#marc_editor_panel").on('autocompleteopen', function(event, data) {
		input = $(event.target); // Get the autocomplete id
		toplevel_li = input.parents("li");
		hidden = toplevel_li.children(".autocomplete_target")
		
		hidden.data("status", "opened");
	});

	$("#marc_editor_panel").on('autocompleteclose', function(event, data) {
		input = $(event.target); // Get the autocomplete id
		toplevel_li = input.parents("li");
		hidden = toplevel_li.children(".autocomplete_target")
		
		console.log(hidden.data("status"));
	});

	$("#marc_editor_panel").on('autocompletechange', function(event, data) {
		input = $(event.target); // Get the autocomplete id
		
		// havigate up to the <li> and down to the hidden elem
		toplevel_li = input.parents("li");
		hidden = toplevel_li.children(".autocomplete_target")
		
		console.log(hidden.data("status"));
		
		if (hidden.data("status") != "selected") {
		
			hidden.val("");
			hidden.removeClass("serialize_marc");
			var element_class = marc_editor_validate_className(hidden.data("tag"), hidden.data("subfield"));
			hidden.removeClass(element_class);
		
			input.addClass("serialize_marc");
			input.addClass("new_autocomplete");
		}
	});

	$("#marc_editor_panel").on('autocompleteresponse', function(event, data) {
		input = $(event.target); // Get the autocomplete id
		toplevel_li = input.parents("li");
		hidden = toplevel_li.children(".autocomplete_target")
		
		if (data.content.length == 0) {
			hidden.data("status", "nomatch");
		}
	});

	$("#marc_editor_panel").on('railsAutocomplete.select', 'input.ui-autocomplete-input', function(event, data){
		input = $(event.target); // Get the autocomplete id
		
		// havigate up to the <li> and down to the hidden elem
		toplevel_li = input.parents("li");
		hidden = toplevel_li.children(".autocomplete_target")
		
		// the data-field in the hidden tells us which
		// field write in the input value. Default is id
		field = hidden.data("field")
		
		hidden.addClass("serialize_marc");
		var element_class = marc_editor_validate_className(hidden.data("tag"), hidden.data("subfield"));
		hidden.addClass(element_class);
		hidden.val(data.item[field]);
		hidden.data("status", "selected");
		
		input.removeClass("serialize_marc");
		input.removeClass("new_autocomplete");

	})
	
	// Add save and preview hotkeys
	$(document).on('keydown', null, 'alt+ctrl+s', function(){
		marc_editor_send_form('marc_editor_panel', marc_editor_get_model());
	});

	$(document).on('keydown', null, 'alt+ctrl+p', function(){
		marc_editor_show_preview();
	});
	
	$(document).on('keydown', null, 'alt+ctrl+n', function(){
		window.location.href = "/" +  marc_editor_get_model() + "/new";
	});
}

function marc_editor_get_triggers() {
	var triggers = {};
	$("[data-trigger]").each(function(){
		var t = $(this).data("triggered");
		if (!t)
			return;
		
		t = t[0];
		
		for (var k in t) {
			// is it there in the final array?
			if (triggers[k]) {
				triggers[k] = triggers[k].concat(t[k]);
				triggers[k] = $.unique(triggers[k]);
			} else {
				triggers[k] = [];
				triggers[k] = t[k];
			}
		}
	});
	
	return triggers;
}

////////////////////////////////////////////////////////////////////
// Pseudo-private functions called from within the marc editor
////////////////////////////////////////////////////////////////////

// Serialize marc to JSON and do an ajax call to save it
// Ajax sends back and URL to redirect to or an error
function _marc_editor_send_form(form_name, rails_model, redirect) {
	redirect = redirect || false;
	form = $('form', "#" + form_name);
	
	// .valid() triggers form validation
	if (!form.valid()) {
		$('#main_content').unblock();
		$('#sections_sidebar_section').unblock();
		return;
	}
	
	var json_marc = serialize_marc_editor_form(form);
	var triggers = marc_editor_get_triggers();

	var url = "/admin/" + rails_model + "/marc_editor_save";
		
	// A bit of hardcoded stuff
	// block the main editor and sidebar
	$('#main_content').block({ message: "" });
	$('#sections_sidebar_section').block({ message: "Saving..." });
		
	$.ajax({
		success: function(data) {
			
			window.onbeforeunload = false;
			// just reload the edit page
			new_url = data.redirect;
			window.location.href = new_url;
		},
		data: {
			marc: JSON.stringify(json_marc),
			id: $('#id').val(), 
			lock_version: $('#lock_version').val(),
			record_type: $('#record_type').val(),
			parent_object_id: $('#parent_object_id').val(),
			parent_object_type: $('#parent_object_type').val(),
			triggers: JSON.stringify(triggers),
			redirect: redirect
		},
		dataType: 'json',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
				if (errorThrown == "Conflict") {
					alert ("Error saving page: this is a stale version");
					
					$('.flashes').empty();
					$('<div/>', {
					    "class": 'flash flash_error',
					    text: 'This page will not be saved: STALE VERSION. Please reload.'
					}).appendTo('.flashes');
					
					$('#main_content').unblock();
					$('#sections_sidebar_section').unblock();
				} else {
					alert ("Error saving page! Please reload the page. (" 
							+ textStatus + " " 
							+ errorThrown + ")");
				}
		}
	});
}

function _marc_editor_preview( source_form, destination, rails_model ) {
	form = $('form', "#" + source_form);
	json_marc = serialize_marc_editor_form(form);
	
	url = "/admin/" + rails_model + "/marc_editor_preview";
	
	$.ajax({
		success: function(data) {
			marc_editor_show_panel(destination);
		},
		data: {
			marc: JSON.stringify(json_marc), 
			marc_editor_dest: destination, 
			id: $('#id').val()
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Error loading preview. (" 
					+ textStatus + " " 
					+ errorThrown);
		}
	});
}

function _marc_editor_help( destination, help, title, rails_model ) {

	url = "/admin/" + rails_model + "/marc_editor_help";
	
	$.ajax({
		success: function(data) {
			marc_editor_show_panel(destination);
		},
		data: {
			help: help,
			title: title,
			marc_editor_dest: destination
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Error loading preview. (" 
					+ textStatus + " " 
					+ errorThrown);
		}
	});
}

function _marc_editor_version_view( version_id, destination, rails_model ) {	
	url = "/admin/" + rails_model + "/marc_editor_version";
	$("#" + destination).block({message: ""});
	
	$.ajax({
		success: function(data) {
			//marc_editor_show_panel(destination);
			$("#" + destination).unblock();
		},
		data: {
			marc_editor_dest: destination, 
			version_id: version_id
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Error loading version. (" 
					+ textStatus + " " 
					+ errorThrown);
		}
	});
}

function _marc_editor_embedded_view(destination, rails_model, id ) {	
	url = "/admin/" + rails_model + "/marc_editor_embedded_show";
	
	$.ajax({
		success: function(data) {
		},
		data: {
			marc_editor_dest: destination,
			object_id: id
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Error loading version. (" 
					+ textStatus + " " 
					+ errorThrown);
		}
	});
}

function _marc_editor_summary_view(destination, rails_model, id ) {	
	url = "/admin/" + rails_model + "/marc_editor_summary_show";
	
	$.ajax({
		success: function(data) {
		},
		data: {
			marc_editor_dest: destination,
			object_id: id
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Error loading version. (" 
					+ textStatus + " " 
					+ errorThrown);
		}
	});
}

function _marc_editor_version_diff( version_id, destination, rails_model ) {	
	url = "/admin/" + rails_model + "/marc_editor_version_diff";
	$("#" + destination).block({message: ""});
	
	$.ajax({
		success: function(data) {
			//marc_editor_show_panel(destination);
			$("#" + destination).unblock();
            $(".subfield_diff_content").each(function() {
		        $(this).html( diffString( $(this).children('.diff_old').html(), $(this).children('.diff_new').html() ) );
	        });
            $('#marc_editor_historic_view .panel').each(function(){
                if($(this).find(".version_diff").length == 0){
                    $(this).hide();
                }
            });
            
            
		},
		data: {
			marc_editor_dest: destination, 
			version_id: version_id
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Error loading diff. (" 
					+ textStatus + " " 
					+ errorThrown);
		}
	});
}

////////////////////////////////////////////////////////////////////
// Top level fuction to be called from the sidebar or hotkeys
////////////////////////////////////////////////////////////////////

function marc_editor_discard_changes_leaving( ) {
    if (newWindowIsSelect()) {
        return "You have a selection window open. Closing the window will lose all the modifications."
    }

	if (marc_editor_form_changed) {
	   return "The modifications on the record will be lost";
   }
}

function marc_editor_cleanp() {
    if (newWindowIsSelect()) {
        newWindowClose();
    }
}

function marc_editor_cancel_form() {
    marc_editor_form_changed = true;
    var loc=location.href.substring(location.href.lastIndexOf("/"), -1);
    window.location=loc;
}

function marc_editor_send_form(redirect) {
	_marc_editor_send_form('marc_editor_panel', marc_editor_get_model(), redirect);
}

function marc_editor_show_preview() {
    // check that there is no new authority because preview is not possible
    cancel = false;
	$('div[data-function="new"]').each(function(){
		if ($(this).is(':visible')) {
            cancel = true;
		}
	});

    if (cancel) {
        alert("There is an unsaved authority file. Please save the source before opining the preview.");
        return;
    }

    _marc_editor_preview('marc_editor_panel','marc_editor_preview', marc_editor_get_model());
    window.scrollTo(0, 0);
}
	
function marc_editor_show_help(help, title) {
	_marc_editor_help('marc_editor_help', help, title, marc_editor_get_model());
	window.scrollTo(0, 0);
}

function marc_editor_version_view(version) {
    _marc_editor_version_view(version, 'marc_editor_historic_view', marc_editor_get_model());
}

function marc_editor_version_diff(version) {
	_marc_editor_version_diff(version, 'marc_editor_historic_view', marc_editor_get_model());
}

function marc_editor_show_panel(panel_name) {
	// Hide all the panels
	$(".panel-hidable").each(function() {
		$(this).hide();
	});
	
	$('#' + panel_name).show();
}

function marc_editor_incipit(clef, keysig, timesig, incipit, target, width) {
	// width is option
	width = typeof width !== 'undefined' ? width : 720;
	
	pae = "@start:pae-file\n";
	pae = pae + "@clef:" + clef + "\n";
	pae = pae + "@keysig:" + keysig + "\n";
	pae = pae + "@key:\n";
	pae = pae + "@timesig:" + timesig + "\n";
	pae = pae + "@data: " + incipit + "\n";
	pae = pae + "@end:pae-file\n";
	
	// Do the call to the verovio helper
	render_music(pae, 'pae', target, width);
}

// This is the last non-ujs function remaining
// it is called when ckicking the "+" button
// near a repeatable field. It makes a copy
// of it
function marc_editor_add_subfield(id) {

	grid = id.parents("tr");
	//ul = grid.siblings(".repeating_subfield");
	ul = $(".repeating_subfield", grid);
	
	li_all = $("li", ul);
	
	li_original = $(li_all[li_all.length - 1]);
	
	new_li = li_original.clone();
	$(".serialize_marc", new_li).each(function() {
		$(this).val("");
	});
	
	ul.append(new_li);
	new_li.fadeIn('fast');

}

// Hardcoded for marc_editor_panel
function marc_editor_get_model() {
	return $("#marc_editor_panel").data("editor-model");
}
