
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

function marc_editor_toggle( id, value ) {
	if (value == null) {
	// toggle
		id.slideToggle(0);
	} else if (value == 0) {
		id.hide();
	} else {
		id.show();
	}
	if (id.css("display") == "none") {
		eval( "$('" + id.selector + "_btn span').removeClass('ui-icon-triangle-1-s')");
		eval( "$('" + id.selector + "_btn span').addClass('ui-icon-triangle-1-w')");
	} else {
		eval( "$('" + id.selector + "_btn span').removeClass('ui-icon-triangle-1-w')");
		eval( "$('" + id.selector + "_btn span').addClass('ui-icon-triangle-1-s')");
	}
}

// init the tags
// called from the edit_wide.rhtml partial and edit_wide.rjs
function marc_editor_init_tags( id ) {
	$(".sortable").sortable({
	   //'handle': 'table._lp_tag_header', 
		stop: function(event, ui) {
			marc_editor_reset_tag_order(ui.item.context.parentNode);
			//alert(ui.item.context.parentNode);
		}	
	});
	
	marc_editor_reset_tag_div( id );
}

function marc_editor_reset_tag_div( id ) {

//	$('textarea.marc_editor_growfield', id).elastic();	
	// this is not great either...
	$(".sortable", id).each(function () {
		marc_editor_reset_tag_order( this )
  });
}

function marc_editor_reset_tag_order( id ) {
	tag_order = new Array();
	
	$("dt", id).each(function (i) {
    i = i+1;
    $("._lp_tag_header label", this).text( "No. " + i );
		// get order of the tags - pretty bad way:
		// get the iterator number (used to create the id of the input)
    parts = this.id.split("-");
		iterator = parseInt(parts[1]);
		tag_order.push(iterator);
		//tag_order.push(String("000" + iterator).slice(-3));
   });
	if (tag_order.length > 0) {
		// if any, put them as value in the parent ordering field
		ordering = $(".marc_editor_ordering", id.parentNode)
		ordering.attr("value",tag_order.join(";"));
	}
	// grow field, nothing to do with the function,... but done here
	//$("textarea.marc_editor_growfield", id).growfield({'restore': true});
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

function marc_editor_add_tag_from_list(destination_column, call_type, list )
{
	val = list.val();
	if (val == '-') {
		return;
	}
	list.find("[value=" + val + "]").attr('disabled',"disabled");
	list.find("[value=-]").attr('selected','selected');
	marc_editor_add_tag(destination_column, call_type + val );
}

// confirmation message for delete
// marc_editor_do_delete_tag if yes 
function marc_editor_delete_tag(destination_column, group, tag_name, iterator) {
	
	$('#dialog').html('<p>' + delete_field_confirm + '</p>');
	$("#dialog").dialog();
	$("#dialog").dialog( 'option', 'title', delete_msg );
	$("#dialog").dialog( 'option', 'width', 300);
	$("#dialog").dialog( 'option', 'buttons', {
				OK: function() {
					marc_editor_do_delete_tag(destination_column, group, tag_name, iterator)
					$(this).dialog('close');
				},
				Cancel: function() { $(this).dialog('close');	}
			});
	$("#dialog").dialog('open');
}
	
function marc_editor_do_delete_tag(destination_column, group, tag_name, iterator) {

	base = "#" + destination_column + "_tag_dt_" + tag_name;
	base_div = "#" + destination_column + "_tag_div_" + tag_name;
 	if (iterator != -1) {
		$(base + "-" + iterator).remove();
	} else { // single tag
		$(base_div + " dt:first").remove();
	}
	// hide tag_div and reset add tag select if empty
	if ($(base_div + " dt").size() == 0) {
		$(base_div).hide();
		$("#" + destination_column + "_add_tag_" + group).find("[value=" + tag_name + "]").removeAttr("disabled");
	} else {
		marc_editor_reset_tag_div( base_div );
	}
}

function marc_editor_set_value( target, render_panel, value ) {
	// we need to escape brackets in jquery, otherwise they are interpreted as selectors
	jquery_target = target.replace(/(\[|\])/g, '\\$1');
	$('#' + jquery_target, '#' + render_panel).val(value);
	$('#in_' + jquery_target, '#' + render_panel).val(value);
}

// Removed in Muscat 3 
// function marc_editor_secondary_value( render_panel, target, ac_type, controller, no_new ) {
// function marc_editor_do_secondary_value( render_panel, target, ac_type ) {


function marc_editor_toggle_lock(force_unlock) {
	if (force_unlock)	{
		$('#marc_editor_lock_btn').show(0);
		$('#marc_editor_unlock_btn').hide(0);
	} else {
		$('#marc_editor_lock_btn').toggle(0);
		$('#marc_editor_unlock_btn').toggle(0);				
	}
}

// navigate in the old version
// item is 'next' or 'prev'
function marc_editor_old_version(item) {
	$('#marc_editor_left_old_versions_panel').carousel(item);
}

// toggle the secondary context
// loads with preview when opening
function marc_editor_toggle_sec_context() {
	// get the old versions
	/*$('#marc_editor_left').carousel('view', 0);
	$('#marc_editor_sec_context_btn').hide(0);
	$('#marc_editor_old_versions_btn').show(0);
	$('#marc_editor_preview_btn').show(0);/*
	// TODO
}

// toggle the old version panel
// loads with marc_editor_populate_versions when opening
// session is required to populate, not to hide
function marc_editor_toggle_old_versions(call_type) {
	// get the old versions
	//$('#marc_editor_left').carousel('next');
	/*$('#marc_editor_left').carousel('view', 1);
	$('#marc_editor_sec_context_btn').show(0);
	$('#marc_editor_old_versions_btn').hide(0);
	$('#marc_editor_preview_btn').show(0);
	// select the marc tab in the main
	$('#marc_editor_panel').tabs( 'select' , 1 );*/
	// load old version
	//if ($('#marc_editor_left_old_versions_panel').hasClass('marc_editor_left_old_versions_panel')) {
	// we're done...
	//	return; // would avoid to reload when shown again, but does not work very wel (carousel)
	//}
	// ... otherwise load the old versions
	marc_editor_populate_versions("marc_editor_left_old_versions_panel", call_type );
}

// toggle the preview
// loads with preview when opening
function marc_editor_toggle_preview() {
	// get the old versions
	/*$('#marc_editor_left').carousel('view', 2);
	$('#marc_editor_sec_context_btn').show(0);
	$('#marc_editor_old_versions_btn').show(0);
	$('#marc_editor_preview_btn').hide(0);
	// select the form tab in the main
	$('#marc_editor_panel').tabs( 'select' , 0 );*/
	// load the form
	marc_editor_send_form('marc_editor_panel','marc_editor_left_preview_panel', 1, "");
	//marc_editor_populate_versions("marc_editor_left_old_versions_panel", call_type );
}

// performs a ajax query to get the old versions of a record
function marc_editor_populate_versions(destination_column, call_type) {

	var call_parts = call_type.split(':');
	var url = "/manuscripts/marc_editor_old_versions";
	var data = "marc_editor_dest=" + destination_column;

	data = data + "&wheel=" + call_parts[0];		
	data = data + "&id=" + $('#marc_editor_panel form :input#id').attr("value");

	$('#' + destination_column).block({ message: "Loading..." });			

	$.ajax({
		success: function() { $('#' + destination_column).unblock(); },
		data: data,
		dataType: 'script',
		timeout: 5000, 
		type: 'get',
		url: url
	});

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

// Deleted in Muscat 3
// function marc_editor_secondary_dialog(destination_column, target, ac_type, no_new)


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

function marc_editor_populate(destination_column, call_type) {

	var call_parts = call_type.split(':');
	// To be fixed
	var url = "/manuscripts/marc_editor_edit";
	var data = "marc_editor_dest=" + destination_column;		
	
	data = data + "&wheel=" + call_parts[0];
	if (call_parts[1] == "next") {
	   if (!marc_editor_discard_changes()) {
	      return;
	   }
		data = data + "&id=next";
	} else if (call_parts[1] == "previous") {
	   if (!marc_editor_discard_changes()) {
	      return;
	   }
		data = data + "&id=previous";
	}
	
	if (destination_column == 'marc_editor_panel') {
		//marc_editor_toggle_old_versions(false);
		if ($('#marc_editor_lock_btn').is(':visible'))	{
			// get the previous item for the left secondary panel
			//data = data + "&previous_item=1";
			marc_editor_send_form('marc_editor_panel','marc_editor_left_secondary_panel', 1, "");
		}
	}
	
	$('#' + destination_column).block({ message: "Loading..." });	
	
	
	$.ajax({
		success: function() { $('#' + destination_column).unblock(); },
		data: data,
		timeout: 10000, 
		dataType: 'script',
		type: 'get',
		url: url
	});

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
function marc_editor_add_tag(destination_column, call_type) {

	var call_parts = call_type.split(':');
	var url = "/sources/marc_editor_add_tag";
	var data = "marc_editor_dest=" + destination_column;

	$('#' + destination_column).block({ message: "Loading..." });	
	
	// get the number of tag currently in the tag list
	i = 0;
	$("dt > div", "#" + destination_column + "_tag_list_" + call_parts[2]).each(function () {
    parts = this.id.split("-");
		iterator = parseInt(parts[1]);
		if (iterator > i) {
			i = iterator
		}
  });
	//i = eval("$('#" + destination_column + "_tag_list_" + call_parts[1] + " dt').size()");
	
	data = data + "&iterator=" + (i + 1);
	data = data + "&profile_id=" + call_parts[0];
	data = data + "&group=" + call_parts[1];
	data = data + "&tag_name=" + call_parts[2];

	$.ajax({
		success: function() { $('#' + destination_column).unblock(); },
		data: data,
		dataType: 'script',
		timeout: 5000, 
		type: 'get',
		url: url
	});

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
		   location.reload();
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
			location.reload();
		}
	});
}

function marc_editor_show_secondary( type, id, create ) {

	$("#dialog_edition").dialog( 'option', 'width', 792 );
   url = "/" + type;
   
   if (create == true) {
      url += "/new";
      $("#dialog_edition").dialog( 'option', 'title', new_secondary );
   } else {    
   	url += "/show/" + id; 
   	$("#dialog_edition").dialog( 'option', 'title', view_secondary ); 
   }
	
	$.ajax({
		success: function() {
		   $('#dialog').dialog('close'); 
		   $("#dialog_edition").dialog('open');
      },
		data: "secondary=true",
		dataType: 'script',
		timeout: 20000, 
		type: 'post',
		url: url
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