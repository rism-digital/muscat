var show_viaf_actions = function () {
	var $viaf_table = $("#viaf_table");

	$("#viaf-sidebar").click(function(){
		marc_editor_show_panel("viaf-form");
	});


	//needs improvement!
	$viaf_table.delegate('.data', 'click', function() {
		_update_form($(this).data("viaf"));
		var elem = $(".tag_container[data-tag='024']");
		field024_2 = elem.find("select.subfield_entry[data-tag='024'][data-subfield='2']")
		field024_2.first().val("VIAF");
	});

	function _update_form(data){
		marc_json = data;
		id = marc_json_get_tags(marc_json, "001")[0].content
		var elem = $(".tag_container[data-tag='024']");
		var collapse = elem.children(".tag_content_collapsable");
		field024_a = elem.find("input.subfield_entry[data-tag='024'][data-subfield='a']").first()
		field024_a[0].value = id;
		field024_a.css("background-color", "#ffffb3");
		tag_header_add_from_empty(elem);
		marc_editor_show_panel("marc_editor_panel");		
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
		row.append($('<td><a class="data" data-viaf=\'' + JSON.stringify(rowData) + '\'>Übernehmen</a></td>'));
	}
};

$(document).ready(show_viaf_actions);


