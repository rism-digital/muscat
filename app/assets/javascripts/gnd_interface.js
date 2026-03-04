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
      complete: function() {
        $('#loader').hide();
      },
      error: function(jqXHR, textStatus, errorThrown) {
        alert(errorThrown);
      },
      success: function(data) {
        if (data.length == 0) {
          alert("Nothing found in the GND.");
        } else {
          draw_table_gnd(data); 
        }
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

  function draw_row_gnd(rowData) {
    const message = I18n.t("select");

    const label = rowData.label;
    const link = rowData.link;
    const description = rowData.description;
    const marcData = rowData.marc;
    const noSelectMsg = rowData.noSelectMsg;

    const $row = $("<tr>");

    $row.append($("<td>").append(
      $("<a>", { target: "_blank", href: link, text: label })
    ));

    for (let i = 0; i < description.length; i++) {
      $row.append($("<td>", { text: description[i] })); // text, not HTML
    }

    const $selectCell = $("<td>");
    if (noSelectMsg === "") {
      const $a = $("<a>", { class: "data", href: "#", text: message });
      $a.data("gnd", marcData); // stores the object safely (no HTML serialization)
      $selectCell.append($a);
    } else {
      $selectCell.text(`[${noSelectMsg}]`);
    }

    $row.append($selectCell);
    $gnd_table.append($row);
  }
};

$(document).ready(show_gnd_actions);
