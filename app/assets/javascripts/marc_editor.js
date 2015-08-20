
var vrvToolkit = null;

// Patch into the global ready function
/*
* Unobtrusive autocomplete
*
* To use it, you just have to include the HTML attribute autocomplete
* with the autocomplete URL as the value
*
*   Example:
*       <input type="text" data-autocomplete="/url/to/autocomplete">
*
* Optionally, you can use a jQuery selector to specify a field that can
* be updated with the element id whenever you find a matching value
*
*   Example:
*       <input type="text" data-autocomplete="/url/to/autocomplete" data-id-element="#id_field">
*/

function marc_editor_discard_changes_leaving( ) {
	if (marc_editor_form_changed) {
	   return "The modifications on the title will be lost";
   }
}

function marc_editor_discard_changes( ) {
   if (!marc_editor_form_changed) {
      return true;     
   }
   var x = window.confirm("Are you sure you want to navigate away from this page?\n\nThe modifications on the title will be lost\n\nPress OK to continue, or Cancel to stay on the current page.");
   return x;
}

function marc_editor_cancel_inline( div_id ) {
   cancel_div_id = div_id.slice( 0, -5 ); // remove the _form ad the end of the id
   $( '#' + cancel_div_id ).show();
   $('#' + div_id ).html("");
}

// init the tags
// called from the edit_wide.rhtml partial
function marc_editor_init_tags( id ) {
	$(".sortable").sortable();

	/* Bind to the global railsAutocomplete. event, thrown when someone selects
	   from an autocomplete field. It is a delegated method so dynamically added
	   forms can handle it
	*/
	$("#marc_editor_panel").on('railsAutocomplete.select', 'input.ui-autocomplete-input', function(event, data){
		input = $(event.target); // Get the autocomplete id
		
		// havigate up to the <li> and down to the hidden elem
		toplevel_li = input.parents("li");
		hidden = toplevel_li.children(".autocomplete_target")
		
		// the data-field in the hidden tells us which
		// field write in the input value. Default is id
		field = hidden.data("field")
		
		// Set the value from the id of the autocompleted elem
		if (data.item[field] == "") {
			alert("Please select a valid item from the list");
			input.val("");
			hidden.val("");
		} else {
			hidden.val(data.item[field]);
		}
	})
	
	// Add save and preview hotkeys
	$(document).on('keydown', null, 'alt+ctrl+s', function(){
		marc_editor_send_form('marc_editor_panel', 'marc_editor_panel', 0, marc_editor_get_model());
	});

	$(document).on('keydown', null, 'alt+ctrl+p', function(){
		marc_editor_show_hide_preview();
	});
	
	$(document).on('keydown', null, 'alt+ctrl+n', function(){
		window.location.href = "/" +  marc_editor_get_model() + "/new";
	});
}

function marc_editor_set_locale( lang ){
      if (lang == null) {
         lang = 'en'; 
      }
		$.localise(
			'rism.localisation', 
			{path: ['/javascripts/','/locale/'], 
			language: lang, 
			loadBase: true 
		});	
}

// load the image into the incipit target
// make sure the size of the div is correct
function marc_editor_incipit_image( target, image ) {
	
  var img = new Image();
  $(img)
     // once the image has loaded, execute this code
    .load(function () {
      // set the image hidden by default    
      $(this).hide();
    
      // with the holding div #loader, apply:
      $('#' + target )
        // remove the loading class (so no background spinner), 
        //.removeClass('loading')
				.html('')
        // then insert our image
        .append(this);
        
        // with the holding div #loader, apply:
        $('#' + target ).parents('table').show();
    
      // fade our image in to create a nice effect
      $(this).show();
    })
    
    // if there was an error loading the image, react accordingly
    .error(function () {
      // notify the user that the image could not be loaded
    })
    
    // *finally*, set the src attribute of the new image to our image
    .attr('src', image)
    .css('display', 'inline');	
}

function marc_editor_add_tag_from_list( list )
{
	val = list.val();
	if (val == '-') {
		return;
	}
	list.find("[value=" + val + "]").attr('disabled',"disabled");
	list.find("[value=-]").attr('selected','selected');
	
	toplevel = list.parents(".marc_editor_panel_content")//.children(".tag_group")
	
	tg = toplevel.find(".tag_group[data-tag='" + val +"']");
	
	placeholder = tg.children(".tag_placeholders");
	dl = tg.children(".marc_editor_tag_block");
	
	new_dt = placeholder.clone()
	new_dt.toggleClass('tag_placeholders tag_toplevel_container');
	new_dt.appendTo(dl);
	new_dt.show()
	
	tg.fadeIn();
}

function marc_editor_edit_inline( destination_column, id, tag_name )
{
	url = "/manuscripts/marc_editor_edit_inline";
	var data = "marc_editor_dest=" + destination_column;
	data = data + "&id=" + id;
	data = data + "&tag_name=" + tag_name;
	
	$.ajax({
		success: function() { 
		},
		data: data,
		dataType: 'script',
		timeout: 20000, 
		type: 'post',
		url: url
	});
}

function marc_editor_new_inline( destination_column, parent_id, tag_name )
{
	url = "/manuscripts/marc_editor_new_inline";
	var data = "marc_editor_dest=" + destination_column;
	data = data + "&parent_id=" + parent_id;
	data = data + "&tag_name=" + tag_name;
	
	$.ajax({
		success: function() { 
		},
		data: data,
		dataType: 'script',
		timeout: 20000, 
		type: 'post',
		url: url
	});
}

var deferred_render_data = []
var verovio_loading = false;

function finalize_verovio () {
	verovio_loading = false
	vrvToolkit = new verovio.toolkit();
	
	for (var i = 0; i < deferred_render_data.length; i++) {
	    data = deferred_render_data[i];
		render_music(data.music, data.format, data.target, data.width);
	}
}

function load_verovio() {
	if (verovio_loading == true) {
		return;
	}
	
	verovio_loading = true;
	
	var element = document.createElement("script");
	element.src = "/javascripts/verovio-toolkit.js";
	document.body.appendChild(element);
	
    element.onreadystagechange = finalize_verovio;
    element.onload = finalize_verovio;

}

function render_music( music, format, target, width )
{	
	width = typeof width !== 'undefined' ? width : 720;
	
	if (vrvToolkit == null) {
		deferred_render_data.push({music: music, format: format, target: target, width: width});
		load_verovio();
		return;
	}
	
	options = JSON.stringify({
				inputFormat: 'pae',
				//pageHeight: 250,
				pageWidth: width / 0.4,
                spacingStaff: 1,
				border: 10,
				scale: 40,
				ignoreLayout: 0,
				adjustPageHeight: 1
			});
	vrvToolkit.setOptions( options );
	vrvToolkit.loadData(music + "\n" );
	svg = vrvToolkit.renderPage(1, "");
	
	//alert(svg);
	$(target).html(svg);
};

function marc_editor_incipit(clef, keysig, timesig, incipit, target, width)
{
	// width is option
	width = typeof width !== 'undefined' ? width : 720;
	
	pae = "@start:pae-file\n";
	pae = pae + "@clef:" + clef + "\n";
	pae = pae + "@keysig:" + keysig + "\n";
	pae = pae + "@key:\n";
	pae = pae + "@timesig:" + timesig + "\n";
	pae = pae + "@data: " + incipit + "\n";
	pae = pae + "@end:pae-file\n";
	render_music(pae, 'pae', target, width);
}

// performs a ajax query to get the old versions of a record
function marc_editor_add_subfield(id) {

	grid = id.parents("tr");
	//ul = grid.siblings(".repeating_subfield");
	ul = $(".repeating_subfield", grid);
	
	li_all = $("li", ul);
	
	li_original = $(li_all[li_all.length - 1]);
	
	new_li = li_original.clone();
	$(".serialize_marc", new_li).each(function() {
		$(this).val("");
		/* JQuery data vs attr
		 The data- attributes are pulled in the first time the data property 
		 is accessed and then are no longer accessed or mutated (all data 
		 values are then stored internally in jQuery).
		*/
		iterator = new Number($(this).attr("data-subfield-iterator"));
		$(this).attr("data-subfield-iterator", iterator + 1);
	});
	
	
	ul.append(new_li);
	new_li.fadeIn('fast');

}

function marc_editor_help( url ) {
   	
	$.ajax({
		success: function(data) {
		   $("#dialog_help").html(data);
		   $("#dialog_help").dialog('open');
		},
		dataType: 'html',
		timeout: 1000, 
		type: 'get',
		url: url
	});
}

/*
 * form_type: 0 = save, 1 = preview, 2 = inline save
 */
function marc_editor_send_form( source_column, destination_column, form_type, rails_model ) {
	form = $('form', "#" + source_column);
	json_marc = serialize_marc_editor_form(form);
	//$(form).valid();
	url = "/admin/" + rails_model + "/marc_editor_save"; ///form.attr("action");
    var marc_id=json_marc["fields"][0]["001"];
	if ( form_type == 1) {
		url = "/"+rails_model;
	}
	else if ( form_type == 2) {
		url = "/manuscripts/marc_editor_save_inline";
	}
	var data = "marc_editor_dest=" + destination_column;
	data = data + "&" + JSON.stringify(json_marc);
	
	// A bit of hardcoded stuff
	// block the main editor and sidebar
	$('#main_content').block({ message: "" });
	$('#sections_sidebar_section').block({ message: "Saving..." });
	
	$.ajax({
		success: function(data) {
			/*
		   $('#' + destination_column).unblock();
		   //location.reload();
		   if (form_type == 0) {
		      marc_editor_form_changed = false;
		   } else if (form_type == 1) {
		      $('#dialog_preview').parent().css('position', 'fixed');
		      $("#dialog_preview").dialog('open');
		   }
           $("html, body").animate({ scrollTop: 0 }, "fast");
           $('#dialog').text("Record saved!").attr("class","flash flash_notice");
		   $(".autogrow").trigger('update'); // Have them grow again
		   window.location.reload();
			*/
			
			new_url = data.redirect;
			window.onbeforeunload = false;
			window.location.href = new_url;
			
		},
		data: {marc: JSON.stringify(json_marc), marc_editor_dest: destination_column, id: $('#id').val(), lock_version: $('#lock_version').val()},
		dataType: 'json',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Error saving page! Page will be reloaded. (" 
					+ textStatus + " " 
					+ errorThrown);
			//location.reload();
		}
	});
}

function marc_editor_preview( source_form, destination, rails_model ) {
	form = $('form', "#" + source_form);
	json_marc = serialize_marc_editor_form(form);
	
	url = "/admin/" + rails_model + "/marc_editor_preview";
	
	$.ajax({
		success: function(data) {
			// Hide and show the divs
			$("#" + source_form).hide();
			$("#" + destination).show();
			
		},
		data: {marc: JSON.stringify(json_marc), marc_editor_dest: destination, id: $('#id').val()},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Error saving page! Page will be reloaded. (" 
					+ textStatus + " " 
					+ errorThrown);
			//location.reload();
		}
	});
}

function marc_editor_version( version_id, destination, rails_model ) {	
	url = "/admin/" + rails_model + "/marc_editor_version";
	
	$.ajax({
		success: function(data) {
			// Hide and show the divs
            // Since we did not pas the source form we cannot hide it... 
            // We will need it depending on the layout we want to have
			//$("#" + source_form).hide();
			$("#" + destination).show();
			
		},
		data: {marc_editor_dest: destination, version_id: version_id},
		dataType: 'script',
		timeout: 20000,
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Error saving page! Page will be reloaded. (" 
					+ textStatus + " " 
					+ errorThrown);
			//location.reload();
		}
	});
}

function quick_search_form( base, lang ) {
   marc_editor_set_locale( lang );
   output = "\
   <div id=\"searchform\" class=\"ui-corner-all\" style=\"width: 350px;\">\
   	<table cellpadding=\"0\" cellspacing=\"\">\
   		<tbody><tr>\
   			<td style=\"padding: 0px 0px 4px 0px;\">"
   			+ quick_search +
            "</td>\
   			<td style=\"padding: 0px 0px 4px 5px;\">\
   				<span class=\"quick_help\"><a name=\"" + tips_on_quick_search + "\" id=\"help_quick\" rel=\"/help/quick_search_" + base + "_" + lang + ".html\" href=\"/help/quick_search_" + base + "_" + lang + ".html\" title=\"" + tips_on_quick_search + "\">?</a></span>\
   			</td>\
   		</tr>\
   	</tbody></table>\
   	<form method=\"get\" class=\"search\" action=\"/manuscripts\">\
   		<input id=\"strategy\" name=\"strategy\" value=\"index\" type=\"hidden\"> \
   		<input id=\"search_1\" name=\"search_1\" class=\"text\" style=\"width: 300px;\" type=\"text\">\
   		<input name=\"search_b\" class=\"button\" value=\"Go!\" type=\"submit\">\
   	</form>\
   </div>";
   return output;
}

function marc_editor_cancel_form( ) {
    marc_editor_form_changed = true;
    var loc=location.href.substring(location.href.lastIndexOf("/"), -1);
    window.location=loc;
}

// Hardcoded for marc_editor_panel
function marc_editor_get_model() {
	return $("#marc_editor_panel").data("editor-model");
}

function marc_editor_show_hide_preview() {
	// Use the commodity function in marc_editor.js
	// model comes from the marc_editor_panel div
	model = marc_editor_get_model();
	
//	if ($('div[data-function="new"]').filter(":visible").size() > 0) {
//		alert("There are unsaved Authority Files. Please save the Source before switching to preview.");
//		return;
//	}

	if ($('div[data-function="new"]').filter(function (index) {
                  return $(this).css("display") === "block";
              }).size() > 0) {
		alert("There are unsaved Authority Files. Please save the Source before switching to preview.");
		return;
	}
	
	if ($('#marc_editor_panel').is(':visible')) {
		// this function gets the show data via ajax
		// it will automatically hide the editor on success
		// or do nothing if there is an error
		marc_editor_preview('marc_editor_panel','marc_editor_preview', model);
	} else {
		$('#marc_editor_preview').hide();
		//$('#marc_editor_panel').show();
	}
	
	window.scrollTo(0, 0);
}
