var show_wikidata_actions = function () {

  $("#wikidata-sidebar").click(function(){
    marc_editor_show_panel("wikidata-form");
    $('#wikidata-form').children('div.tab_panel').show();
  });

  function searchWikidata() {
    var term = $("#wikidata_input").val();
    var model = $("#marc_editor_panel").attr("data-editor-model");
    const isNew = $("body").hasClass("new");

    $.ajax({
      type: "GET",
      url: "/admin/" + model + "/wikidata_merge.json",
      data: { wikidata_id: term, new: isNew },

      beforeSend: function() {
        $("#loader").show();
      },

      complete: function() {
        $("#loader").hide();
      },

      success: function(response) {
        var data = response.data || response;
        _marc_editor_update_from_json(data, ["001", "040", "042", "100"], true);
        marc_editor_show_panel("marc_editor_panel");
      },

      error: function(jqXHR, textStatus, errorThrown) {
        var message = "Request failed";

        if (jqXHR.responseJSON && jqXHR.responseJSON.error) {
          message = jqXHR.responseJSON.error;
        } else if (jqXHR.responseText) {
          try {
            message = JSON.parse(jqXHR.responseText).error || jqXHR.responseText;
          } catch (e) {
            message = jqXHR.responseText;
          }
        } else if (errorThrown) {
          message = errorThrown;
        }

        console.log(message);
        alert(message);
      }
    });
  }

  $("#wikidata_button").click(function(){ 
    searchWikidata()
  })

  $('#wikidata_input').keydown(function (e) {
    var keyCode = e.keyCode || e.which;
    if (keyCode == 13) { 
      searchWikidata()
    }
  });

};

$(document).ready(show_wikidata_actions);
