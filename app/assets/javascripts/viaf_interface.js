var show_viaf_actions = function () {
  var $viaf_table = $("#viaf_table");

  $("#viaf-sidebar").click(function(){
    marc_editor_show_panel("viaf-form");
    $('#viaf-form').children('div.tab_panel').show();
  });

  $viaf_table.on('click', '.data', function() {
    _marc_editor_update_from_json($(this).data("viaf"),["100"], true);
    marc_editor_show_panel("marc_editor_panel");
  });

  function searchViaf(){
    $viaf_table.html("");
    var term = $("#viaf_input").val();
    var model = $("#marc_editor_panel").attr("data-editor-model");
      $.ajax({
        type: "GET",
        url: "/admin/"+model+"/viaf.json?viaf_input="+term,
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
          drawTable(data);
        }
      });
  }

  $("#viaf_button").click(function(){ 
    searchViaf()
  })

  $('#viaf_input').keydown(function (e) {
    var keyCode = e.keyCode || e.which;
    if (keyCode == 13) { 
      searchViaf()
    }
  });

  function drawTable(data) {
    for (var i = 0; i < data.length; i++) {
      drawRow(data[i]);
    }
  }

  function drawRow(rowData) {
    var locale = $viaf_table.attr("locale")
    var message = {"de": "übernehmen", "en": "select", "fr": "choisir", "it": "scegliere"}[locale]
    var id = marc_json_get_tags(rowData, "001")[0].content;
    var tag100 = marc_json_get_tags(rowData, "100")[0]
    var tag24 = marc_json_get_tags(rowData, "024")[1]
    var model = $("#marc_editor_panel").attr("data-editor-model");
    var row = $("<tr />")
    $viaf_table.append(row); 
    row.append($("<td><a target=\"_blank\" href=\"http://viaf.org/viaf/" + id + "\">" + id + "</a></td>"));
    row.append($("<td>" + tag100["a"] + "</td>"));
    if(model=="works"){
      row.append($("<td>" + (tag100["t"] ? tag100["t"] : "") + "</td>"));
    }
    else{
      row.append($("<td>" + (tag100["d"] ? tag100["d"] : "") + "</td>"));
    }
    row.append($("<td>" + ( (typeof(tag24)!='undefined') ? tag24["2"] : "") + "</td>"));
    row.append($('<td><a class="data" id="viaf_data" href="#" data-viaf=\'' + JSON.stringify(rowData) + '\'>' + message  + '</a></td>'));
  }
};

$(document).ready(show_viaf_actions);
