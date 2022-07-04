var show_gnd_actions = function () {
  var $gnd_table = $("#gnd_table");

  $("#gnd-sidebar").click(function(){
    marc_editor_show_panel("gnd-form");
    $('#gnd-form').children('div.tab_panel').show();
  });

  $gnd_table.on('click', '.data', function() {
    _marc_editor_update_from_json($(this).data("gnd"), ["100"]);
    marc_editor_show_panel("marc_editor_panel");
  });

  function search_gnd() {
    $gnd_table.html("");
    var term = $("#gnd_input").val();
    var model = $("#marc_editor_panel").attr("data-editor-model");
      $.ajax({
        type: "GET",
        url: "/admin/"+model+"/gnd.json?gnd_input="+term,
        beforeSend: function() { 
          $('#loader').show();
        },
        complete: function(){
          $('#loader').hide();
        },
        error: function(jqXHR, textStatus, errorThrown) {
          alert(jqXHR.responseText);
        },
        success: function(data){
          var result = (JSON.stringify(data));
          draw_table_gnd(data);
        }
      });
  }

  $("#gnd_button").click(function(){ 
    search_gnd()
  })

  $('#gnd_input').keydown(function (e) {
    var keyCode = e.keyCode || e.which;
    if (keyCode == 13) { 
      search_gnd()
    }
  });

  function draw_table_gnd(data) {
    for (var i = 0; i < data.length; i++) {
      draw_row_gnd(data[i]);
    }
  }

  function draw_row_gnd( rowData ) {
    var label = rowData["label"];
    var link = rowData["link"];
    var description = rowData["description"];
    var marcData = rowData["marc"];
    var noSelectMsg = rowData["noSelectMsg"];
    var selectRow = (noSelectMsg == "") ? '<a class="data" id="gnd_data" href="#" data-gnd=\'' + JSON.stringify( marcData ) + '\'>' + message + '</a>' : '[' + noSelectMsg + ']'

    locale = $gnd_table.attr( "locale" )
    message = I18n.t("select")

    var row = $( "<tr>" );
    row.append( $( "<td><a target=\"_blank\" href=\"" + link + "\">" + label + "</a></td>" ) );
    for(let i = 0; i < description.length; i++) row.append($("<td>" + description[i] + "</td>"));
    row.append( $( '<td>' + selectRow + '</td>' ) );
    row.append( $( "</tr>" ) );
    $gnd_table.append(row); 
  }
};

$(document).ready(show_gnd_actions);
