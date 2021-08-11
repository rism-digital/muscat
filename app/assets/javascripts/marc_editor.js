////////////////////////////////////////////////////////////////////
// Init the tags called from the edit_wide.rhtml partial
////////////////////////////////////////////////////////////////////
marc_editor_form_changed = false;

function marc_editor_set_dirty() {
	marc_validate_force_evaluate_warnings(); // Force the warnings to re-evaluate
	if (marc_editor_form_changed == true)
		return;
	
	marc_editor_form_changed = true
	//$("<span>*</span>").insertAfter($("#page_title"));
	$("#page_title").append("*");
}
	
function marc_editor_init_tags( id ) {
    
  marc_editor_show_last_tab();
	
	// Set event hooks
	// avoid user to accidently leave the page when the form was modify 
	// will ask for a confirmation
	window.onbeforeunload = marc_editor_discard_changes_leaving;
	window.onunload = marc_editor_cleanp;
	
	$(".sortable").sortable();

	marc_editor_form_changed = false;
	$(id).dirtyFields({
		trimText: true,
		fieldChangeCallback: function(originalValue, isDirty) {
			marc_editor_set_dirty();
		}
	});	
	
	// Add save and preview hotkeys
	$(document).on('keydown', null, 'alt+ctrl+s', function(){
		marc_editor_send_form('marc_editor_panel', marc_editor_get_model());
	});

	$(document).on('keydown', null, 'alt+ctrl+p', function(){
		marc_editor_show_preview();
	});
	
	$(document).on('keydown', null, 'alt+ctrl+n', function(){
		window.location.href = "/admin/" +  marc_editor_get_model() + "/new";
	});
	
	// Bind all the autocomplete events
	// see autocomplete_events.js
	bind_autocomplete_events();
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
var savedNr = 0;
function _marc_editor_send_form(form_name, rails_model, redirect) {
	savedNr++;
	redirect = redirect || false;
	form = $('form', "#" + form_name);
	
	// Warning level works like this: first time it shows warnings
	// second time it passes. See if warning are present so
	// if this is the second load it will pass
	var already_warnings = marc_validate_has_warnings();
	marc_validate_hide_warnings(); // Delete all the old warnings
	marc_validate_reset_warnings(); // Reset all the warnings if the user fixed them
	// Warnings will be re-drawn if needed
	
	// Delete the "errors" message
	$("#validation_errors").hide();
	
	// .valid() triggers form validation
	// it also populates the warning hash
	var form_valid = form.valid();

	// Warning in the validation on a new validation (i.e. no 
	// warnings already there)
	if (marc_validate_has_warnings()) {
		$('#main_content').unblock();
		$('#sections_sidebar_section').unblock();
		$("#validation_warnings").show();
		
		marc_validate_show_warnings();
		// If the form is valid AND it is the first submission
		// after something changed in the editor, inhibit submit
		// if the form is INVALID submit is ALWAYS blocked,
		// see below
		if (form_valid && !already_warnings) {
			return; // Give the user a chance to resubmit
		}
	} else {
		$("#validation_warnings").hide();
	}

	// Run the validation on the server side
	var backend_validation = marc_editor_validate();

	if (!form_valid || !backend_validation.responseJSON["status"].endsWith("[200]")) {
		var superuser = ($('#user_skip_validation').val() == "True");
		var skip = false;

		// Admins and editors can skip the validation
		if (superuser) {
			if (savedNr >= 2) {
				skip = confirm("The record does not pass validation, are you sure you want to save it?");
			}
		}

		if (!skip) {
			$('#main_content').unblock();
			$('#sections_sidebar_section').unblock();
			$("#validation_errors").show();
			
			return;
		}
		/*
		// Show the validation override check
		$("#validation_override_container").show();
		
		// If it is not checked just return
		// default state is unckecked
		// If checked go on at the editor's risk
		if ( !$("#validation_override_checkbox").is(':checked') )
			return;
		*/
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
		async: true,
		data: {
			marc: JSON.stringify(json_marc),
			id: $('#id').val(), 
			lock_version: $('#lock_version').val(),
			record_type: $('#record_type').val(),
			parent_object_id: $('#parent_object_id').val(),
			parent_object_type: $('#parent_object_type').val(),
			record_status: $('#record_status').val(),
			record_owner: $('#record_owner').val(),
			// Record audit is unused and disabled
			//record_audit: $('#record_audit').val(),
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
					alert ("Error saving page! Please try again. (" 
							+ textStatus + " " 
							+ errorThrown + ")");

					$('#main_content').unblock();
					$('#sections_sidebar_section').unblock();
				}
		}
	});
}

function _marc_editor_preview( source_form, destination, rails_model ) {
	var form = $('form', "#" + source_form);
	var json_marc = serialize_marc_editor_form(form);
	
	var url = "/admin/" + rails_model + "/marc_editor_preview";
	
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

function _marc_editor_validate(source_form, destination, rails_model) {
    var form = $('form', "#" + source_form);
    var json_marc = serialize_marc_editor_form(form);
    var url = "/admin/" + rails_model + "/marc_editor_validate";
    return $.ajax({
        success: function(data) {
            var message_box = $("#marc_errors");
            var message = data["status"];
            if (message.endsWith("[200]")) {
                message_box.html(message).removeClass('flash_error').addClass('flash_notice').css('visibility', 'visible');
            } else {
                message_box.html(message.replace(/\t/g, "&nbsp;").replace(/\n/g, "<br>")).removeClass('flash_notice').addClass('flash_error').css('visibility', 'visible');
            }
        },
        data: {
            marc: JSON.stringify(json_marc),
            marc_editor_dest: destination,
            id: $('#id').val(),
            record_type: $('#record_type').val(),
            current_user: $('#current_user').find('a').attr('href').split("/")[3],
        },
        dataType: 'json',
        timeout: 60000,
        type: 'post',
        url: url,
        // FIXME make this async
        'async': false,
        error: function(jqXHR, textStatus, errorThrown) {
            alert("Error in validation process. (" +
                textStatus + " " +
                errorThrown);
        }
    });
}

function _marc_editor_help( destination, help, title, rails_model ) {

	var url = "/admin/" + rails_model + "/marc_editor_help";
	
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
					+ errorThrown + ")");
		}
	});
}

function _marc_editor_embedded_holding(destination, rails_model, id, opac ) {	
	url = "/catalog/holding";
	
	$.ajax({
		success: function(data) {
		},
		data: {
			marc_editor_dest: destination,
			object_id: id,
			opac: opac
		},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Error loading holding information. " +
					"(" + textStatus + " " 
					+ errorThrown + ")");
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
			alert ("Error loading summary. (" 
					+ textStatus + " " 
					+ errorThrown + ")");
		}
	});
}

function _marc_editor_version_diff( version_id, destination, rails_model ) {	
	var url = "/admin/" + rails_model + "/marc_editor_version_diff";
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
    var loc = location.href.substring(location.href.lastIndexOf("/"), -1);
    window.location=loc;
}

function marc_editor_send_form(redirect) {
	_marc_editor_send_form('marc_editor_panel', marc_editor_get_model(), redirect);
}

function marc_editor_show_preview() {
    _marc_editor_preview('marc_editor_panel','marc_editor_preview', marc_editor_get_model());
    window.scrollTo(0, 0);
}

function marc_editor_validate() {
    return _marc_editor_validate('marc_editor_panel','marc_editor', marc_editor_get_model());
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

function marc_editor_show_tab_in_panel(tab_name, panel_name) {
	// Hide all the other panels
	$( ".tab_panel" ).each(function() {
		if ($(this).attr("name") != tab_name) {
			$(this).hide();
		} else {
			$(this).show();
		}
	});	
	marc_editor_show_panel(panel_name)
}

function marc_editor_show_all_subpanels() {
	$( ".tab_panel" ).each(function() {
		$(this).show();
		$(this).removeData("current-item");
	})
}

function marc_editor_set_last_tab(tab_name, panel_name) {
	Cookies.set(marc_editor_get_model() + '-last_tab', tab_name, { expires: 30 });
	Cookies.set(marc_editor_get_model() + '-panel_name', panel_name, { expires: 30 });
	
	// Save the last object id
	Cookies.set(marc_editor_get_model() + '-last_id', $("#id").val(), { expires: 30 });
}

function marc_editor_show_last_tab() {
    var last_tab = Cookies.get(marc_editor_get_model() + '-last_tab');
    var panel_name = Cookies.get(marc_editor_get_model() + '-panel_name');
	var last_id = Cookies.get(marc_editor_get_model() + '-last_id');
	var current_id = $("#id").val();
	
	var elem = $("[name='" + last_tab + "']")
		
	if ((last_tab != "full") 
		&& (last_tab && panel_name) 
		&& elem.length > 0
		&& current_id == last_id)
	{
        marc_editor_show_tab_in_panel(last_tab, panel_name);
    } else {
		marc_editor_set_last_tab("full", "full");
    	marc_editor_show_all_subpanels();
    }
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
	
	var pae = "@start:pae-file\n";
	pae = pae + "@clef:" + clef + "\n";
	pae = pae + "@keysig:" + keysig + "\n";
	pae = pae + "@key:\n";
	pae = pae + "@timesig:" + timesig + "\n";
	pae = pae + "@data: " + incipit + "\n";
	pae = pae + "@end:pae-file\n";
	
	// Do the call to the verovio helper
	render_music(pae, 'pae', target, width);
}

// These two are the last non-ujs function remaining
// This one is called when ckicking the "+" button
// near a repeatable field. It makes a copy
// of it
function marc_editor_add_subfield(id) {

	var grid = id.parents("tr");
	//ul = grid.siblings(".repeating_subfield");
	var ul = $(".repeating_subfield", grid);
	
	var li_all = $("li", ul);
	
	var li_original = $(li_all[li_all.length - 1]);
	
	var new_li = li_original.clone();
	$(".serialize_marc", new_li).each(function() {
		$(this).val("");
	});
	
	$(".add-button", new_li).each(function() {
		$(this).hide();
	});

	// This is a special case for the light-weight "t" tag
	// in 031, as it is a select_subfield which normally is
	// never repeatable, but in this case, since it does not
	// make a $0 link in MARC, it can be repeatable. The
	// caveat is that the text box will not have .serialize_marc
	// as that is assigned to the hidden item (and cleared
	// with the code above), so we need a special cleanup
	// only for this. It is used only in 031 $t
	$(".autocomplete_new_window", new_li).each(function() {
		$(this).val("");
		console.log("emptied .autocomplete_new_window in marc_editor_add_subfield");
	});

	ul.append(new_li);
	new_li.fadeIn('fast');

}

// This one removes the item
function marc_editor_remove_subfield(id) {

	var element = id.parents("li");

	var button = $(".add-button", element);
	if (button.is(":visible")) {
		var grid = id.parents("tr");
		var ul = $(".repeating_subfield", grid);

		if ($(ul).children().length == 1) {
			$(".serialize_marc", element).each(function() {
				$(this).val("");
			});
		} else {
			element.remove();
			
			var next = $(ul).children()[0]

			var add_button = $(".add-button", next);
			add_button.show();

		}
	} else {
		element.remove();
	}
}

// Hardcoded for marc_editor_panel
function marc_editor_get_model() {
	return $("#marc_editor_panel").data("editor-model");
}
