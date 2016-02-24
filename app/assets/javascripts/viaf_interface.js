var show_viaf_actions = function () {
	var $viaf_table = $("#viaf_table");

	$("#viaf-sidebar").click(function(){
		marc_editor_show_panel("viaf-form");
	});

	$viaf_table.delegate('.data', 'click', function() {
		console.log($(this).data("viaf"));
		alert(JSON.stringify($(this).data("viaf")));
	});

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


