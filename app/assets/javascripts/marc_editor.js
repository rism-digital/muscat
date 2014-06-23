
// This is a slight variation of Henrik Nyh’s code, which fixes an issue with IE6 that makes all Ajax requests use POST in IE6.
// 
// In application.html.erb, or whatever layout file you’re using, put:
// 
//    1  <%= javascript_tag "window.AUTH_TOKEN = '#{form_authenticity_token}';" %>
// 
// In application.js, or whatever JavaScript file you’re using, put:
// 
//    1  $(document).ajaxSend(function(event, request, settings) {
//    2    if (typeof(window.AUTH_TOKEN) == "undefined") return;
//    3    // IE6 fix for http://dev.jquery.com/ticket/3155
//    4    if (settings.type == 'GET' || settings.type == 'get') return;
//    5  
//    6    settings.data = settings.data || "";
//    7    settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(window.AUTH_TOKEN);
//    8  });


// confirmation message for leaving the window

var vrvToolkit = null;

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

function marc_editor_toggle( id, value) {
	
	tag_container = id.parents(".tag_container");
	collapsable = tag_container.children(".tag_content_collapsable");
	
	if (value == null) {
	// toggle
		collapsable.slideToggle(0);
	} else if (value == 0) {
		collapsable.hide();
	} else {
		collapsable.show();
	}
	
	span = id.children("span");
	
	if (collapsable.css("display") == "none") {
		span.removeClass('ui-icon-triangle-1-s');
		span.addClass('ui-icon-triangle-1-w');
	} else {
		span.removeClass('ui-icon-triangle-1-w');
		span.addClass('ui-icon-triangle-1-s');
	}
}

// init the tags
// called from the edit_wide.rhtml partial and edit_wide.rjs
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
		
		// Set the value from the id of the autocompleted elem
		if (data.item.id == "") {
			alert("Please select a valid item from the list");
			input.val("");
			hidden.val("");
		} else {
			hidden.val(data.item.id);
		}
	})

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
	
	toplevel = list.parents(".panel_content")//.children(".tag_group")
	
	tg = toplevel.find(".tag_group[data-tag='" + val +"']");
	
	placeholder = tg.children(".tag_placeholders");
	dl = tg.children(".marc_editor_tag_block");
	
	new_dt = placeholder.clone()
	new_dt.toggleClass('tag_placeholders tag_toplevel_container');
	new_dt.appendTo(dl);
	new_dt.show()
	
	tg.fadeIn();
}

// confirmation message for delete
// marc_editor_do_delete_tag if yes 
function marc_editor_delete_tag(child_id) {
		
	$('#dialog').html('<p>' + delete_field_confirm + '</p>');
	$("#dialog").dialog();
	$("#dialog").dialog( 'option', 'title', delete_msg );
	$("#dialog").dialog( 'option', 'width', 300);
	$("#dialog").dialog( 'option', 'buttons', {
		OK: function() {
			marc_editor_do_delete_tag(child_id)
			$(this).dialog('close');
		},
		Cancel: function() { $(this).dialog('close');	}
		});
	$("#dialog").dialog('open');
}
	
function marc_editor_do_delete_tag(child_id) {
	
	dt_id = child_id.parents(".tag_toplevel_container");
	tag = dt_id.data("tag");
	
	// Enable the tag menu
	tag_menu = dt_id.parents(".panel_content");
	tag_menu.find("[value=" + tag + "]").removeAttr("disabled");
	
	dt_id.fadeOut('fast', function() {
		dt_id.remove();
	});
	
	
}

function marc_editor_set_value( target, render_panel, value ) {
	// we need to escape brackets in jquery, otherwise they are interpreted as selectors
	jquery_target = target.replace(/(\[|\])/g, '\\$1');
	$('#' + jquery_target, '#' + render_panel).val(value);
	$('#in_' + jquery_target, '#' + render_panel).val(value);
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
		render_music(data.music, data.format, data.target);
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

function render_music( music, format, target )
{	
	
	if (vrvToolkit == null) {
		deferred_render_data.push({music: music, format: format, target: target});
		load_verovio();
		return;
	}
	
	options = JSON.stringify({
				inputFormat: 'pae',
				//pageHeight: 250,
				pageWidth: 1350,
				border: 0,
				scale: 50,
				ignoreLayout: 0,
				adjustPageHeight: 1
			});
	vrvToolkit.setOptions( options );
	vrvToolkit.loadData(music + "\n" );
	svg = vrvToolkit.renderPage(1, "");
	
	//alert(svg);
	$('#' + target).html(svg);
};

function marc_editor_incipit(destination_column, clef, keysig, timesig, incipit, target)
{
	
	jquery_clef = clef.replace(/(\[|\])/g, '\\$1');
	jquery_keysig = keysig.replace(/(\[|\])/g, '\\$1');
	jquery_timesig = timesig.replace(/(\[|\])/g, '\\$1');
	jquery_incipit = incipit.replace(/(\[|\])/g, '\\$1');

	pae_clef = $('#' + jquery_clef).val();
	pae_keysig =  $('#' + jquery_keysig).val();
	pae_timesig = $('#' + jquery_timesig).val();
	pae_incipit = $('#' + jquery_incipit).val();


	pae = "@start:pae-file\n";
	pae = pae + "@clef:" + pae_clef + "\n";
	pae = pae + "@keysig:" + pae_keysig + "\n";
	pae = pae + "@key:\n";
	pae = pae + "@timesig:" + pae_timesig + "\n";
	pae = pae + "@data: " + pae_incipit + "\n";
	pae = pae + "@end:pae-file\n"
	render_music(pae, 'pae', target);
	
	/*
	jquery_clef = clef.replace(/(\[|\])/g, '\\$1');
	jquery_keysig = keysig.replace(/(\[|\])/g, '\\$1');
	jquery_timesig = timesig.replace(/(\[|\])/g, '\\$1');
	jquery_incipit = incipit.replace(/(\[|\])/g, '\\$1');
	var url = "/manuscripts/marc_editor_incipit";
	var data = "marc_editor_dest=" + destination_column;	
	data = data + "&clef=" + $('#' + jquery_clef).val();
	data = data + "&keysig=" + $('#' + jquery_keysig).val();
	data = data + "&timesig=" + $('#' + jquery_timesig).val();
	data = data + "&incipit=" + $('#' + jquery_incipit).val();
	data = data + "&target=" + target;
	//alert($('#' + jquery_incipit).val());

	$.ajax({
		success: function() { },
		data: data,
		timeout: 5000, 
		dataType: 'script',
		type: 'post',
		url: url
	});
	*/
}

// performs a ajax query to get the old versions of a record
function marc_editor_add_subfield(destination_column, call_type) {

	var call_parts = call_type.split(':'); // profile_id:group:tag_name:iterator:subfield_name
	var url = "/sources/marc_editor_add_subfield";
	var data = "marc_editor_dest=" + destination_column;
	var list = destination_column + "_subfield_" + call_parts[2] + "-" + call_parts[3]  + "-" + call_parts[4];

	//$('#' + destination_column).block({ message: "Loading..." });	
	
	// get the number of tag currently in the tag list
	last = $("li:last", "#" + list);
	parts = last[0].id.split("-");
	s_iterator = parseInt(parts[1]);

	//i = eval("$('#" + destination_column + "_tag_list_" + call_parts[1] + " dt').size()");
	
	data = data + "&profile_id=" + call_parts[0];
	data = data + "&group=" + call_parts[1];
	data = data + "&tag_name=" + call_parts[2];
	data = data + "&iterator=" + call_parts[3];
	data = data + "&subfield_name=" + call_parts[4];
	data = data + "&s_iterator=" + (s_iterator + 1);

	$.ajax({
		success: function() { /*$('#' + destination_column).unblock();*/ },
		data: data,
		dataType: 'script',
		timeout: 5000, 
		type: 'get',
		url: url
	});

}

// performs a ajax query to get the old versions of a record
function marc_editor_add_tag(current_tag) {
	placeholder = current_tag.parents(".tag_group").children(".tag_placeholders");
	current_dt = current_tag.parents(".tag_toplevel_container");
	
	new_dt = placeholder.clone()
	new_dt.toggleClass('tag_placeholders tag_toplevel_container');
	new_dt.insertAfter(current_dt);
	new_dt.fadeIn('fast');
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
function marc_editor_send_form( source_column, destination_column, form_type, wheel ) {
   
	form = $('form', "#" + source_column);
	json_marc = serialize_marc_editor_form(form);
	
	//$(form).valid();
	url = "/sources/marc_editor_save"; ///form.attr("action");
	if ( form_type == 1) {
		url = "/manuscripts/marc_editor_preview";
	}
	else if ( form_type == 2) {
		url = "/manuscripts/marc_editor_save_inline";
	}
	var data = "marc_editor_dest=" + destination_column;
	data = data + "&" + JSON.stringify(json_marc);
	
	$('#' + destination_column).block({ message: "Loading..." });
	
	$.ajax({
		success: function() { 
		   $('#' + destination_column).unblock();
		   //location.reload();
		   if (form_type == 0) {
		      marc_editor_form_changed = false;
		   } else if (form_type == 1) {
		      $('#dialog_preview').parent().css('position', 'fixed');
		      $("#dialog_preview").dialog('open');
		      //$('#dialog_preview').parent().css('position', 'fixed');
		   }
		},
		data: {marc: JSON.stringify(json_marc), marc_editor_dest: destination_column},
		//dataType: 'script',
		timeout: 20000, 
		type: 'post',
		url: url, 
		error: function (jqXHR, textStatus, errorThrown) {
			alert ("Editor reload failed (but data saved). Page will be reloaded. (" 
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

function marc_editor_swap(id, editing) {
	
	dt = id.parents(".tag_toplevel_container");
	
	if (editing) {
		var show_id = dt.find('.tag_container[data-function="new"]');
		var hide_id = dt.find('.tag_container[data-function="edit"]');
	} else {
		var show_id = dt.find('.tag_container[data-function="edit"]');
		var hide_id = dt.find('.tag_container[data-function="new"]');
	}
		
    $(hide_id).fadeOut('fast', function(){
        $(show_id).fadeIn('fast');
    });
}