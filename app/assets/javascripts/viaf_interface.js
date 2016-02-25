var show_viaf_actions = function () {
	var $viaf_table = $("#viaf_table");

	$("#viaf-sidebar").click(function(){
		marc_editor_show_panel("viaf-form");
	});

	$viaf_table.delegate('.data', 'click', function() {
		_update_form($(this).data("viaf"));
		marc_editor_show_panel("marc_editor_panel");
	});

	function _update_form(data){
		id = marc_json_get_tags(data, "001")[0]
		if (_size_of_marc_tag("024") == 0){
			_new_marc_tag("024", id);
		}
		else{
			_append_marc_tag("024", id);
		}
		//update only if new record; needs improvement
		//check if new record
		_edit_marc_tag("100", marc_json_get_tags(data, "100")[0])
	}

	$("#viaf_button").click(function(){
		$viaf_table.html("");
		var term = $("#viaf_input").val();
		$.ajax({
			type: "GET",
			url: "/admin/people/viaf.json?viaf_input="+term,
			beforeSend: function() {
				$('#loader').show();
			},
			complete: function(){
				$('#loader').hide();
			},
			success: function(data){
				var result = (JSON.stringify(data));
				drawTable(data);
			}
		});
	});

	function drawTable(data) {
		for (var i = 0; i < data.length; i++) {
			drawRow(data[i]);
		}
	}

	function drawRow(rowData) {
		var id = marc_json_get_tags(rowData, "001")[0].content;
		var tag100 = marc_json_get_tags(rowData, "100")[0]
		var row = $("<tr />")
		$viaf_table.append(row); 
		row.append($("<td><a target=\"_blank\" href=\"http://viaf.org/viaf/" + id + "\">" + id + "</a></td>"));
		row.append($("<td>" + tag100["a"] + "</td>"));
		row.append($("<td>" + (tag100["d"] ? tag100["d"] : "") + "</td>"));
		row.append($("<td>" + tag100["0"] + "</td>"));
		row.append($('<td><a class="data" href="#" data-viaf=\'' + JSON.stringify(rowData) + '\'>Übernehmen</a></td>'));
	}
};

function _new_marc_tag(target, data) {
	field = $(".tag_placeholders[data-tag='"+ target +"']")
	group = field.parents(".tag_group");
	block = group.children(".marc_editor_tag_block");
	new_dt = field.children(".tag_container").clone();
	subfield = new_dt.find("input.subfield_entry[data-tag='" + target + "'][data-subfield='a']").first()
	subfield.val(data.content);
	if(data.tag == "001"){
		provider = new_dt.find("select.subfield_entry[data-tag='" + target + "'][data-subfield='2']").first()
		provider.val("VIAF");
	}
	subfield.css("background-color", "#ffffb3");
	new_dt.toggleClass('tag_placeholders tag_toplevel_container');
	block.append(new_dt);
	_update_empty_marc_tag(group);
}

function _edit_marc_tag(target, data) {
	block = $(".marc_editor_tag_block[data-tag='" + target + "']")
	field = block.find("input.subfield_entry[data-tag='" + target + "'][data-subfield='a']").first()
	field.val(data["a"]);
	field.css("background-color", "#ffffb3");
}


function _append_marc_tag(target, data) {
	block = $(".marc_editor_tag_block[data-tag='" + target + "']")
	placeholder = block.parents(".tag_group").children(".tag_placeholders_toplevel").children(".tag_placeholders");
	new_dt = placeholder.clone()
	subfield = new_dt.find("input.subfield_entry[data-tag='" + target + "'][data-subfield='a']").first()
	subfield.val(data.content);
	if(data.tag == "001"){
		provider = new_dt.find("select.subfield_entry[data-tag='" + target + "'][data-subfield='2']").first()
		provider.val("VIAF");
	}
	subfield.css("background-color", "#ffffb3");
	new_dt.toggleClass('tag_placeholders tag_toplevel_container');
	block.append(new_dt)
	new_dt.show()
}


function _size_of_marc_tag(tag){
	fields = $(".tag_toplevel_container[data-tag='"+ tag +"']")
	return fields.size()		
}


function _update_empty_marc_tag(tag_group) {
	if ( tag_group.children(".marc_editor_tag_block").children().size() > 0 ) {
		tag_group.children(".tag_empty_container").hide();
	}
	else {
		tag_group.children(".tag_empty_container").show();
	}
}


$(document).ready(show_viaf_actions);


