var show_viaf_actions = function () {
  var $viaf_table = $("#viaf_table");

	$("#viaf-sidebar").click(function(){
    marc_editor_show_panel("viaf-form");
		//$("#viaf-form").toggle();
				//$("#marc_editor_panel").toggle();
	});

  $viaf_table.delegate('.data', 'click', function() {
      console.log($(this).data("viaf"));
      alert(JSON.stringify($(this).data("viaf"))); //alert(JSON.stringify($(this).first)); //alert("huhu");
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
    var row = $("<tr />")
    $viaf_table.append(row); //this will append tr element to table... keep its reference for a while since we will add cels into it
    row.append($("<td><a target=\"_blank\" href=\"http://viaf.org/viaf/" + rowData.id + "\">" + rowData.id + "</a></td>"));
    row.append($("<td>" + rowData.name + "</td>"));
    row.append($("<td>" + rowData.dates + "</td>"));
    row.append($("<td>" + rowData.source + "</td>"));
    //console.log(JSON.stringify(rowData));
    //row.append($('<td><a class="data">Übernehmen</a></td>').data('key', rowData));
    row.append($('<td><a class="data" data-viaf=\'' + JSON.stringify(rowData) + '\'>Übernehmen</a></td>'));
  }
	
};

$(document).ready(show_viaf_actions);


