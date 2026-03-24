function initExternalFetchPanel($panel) {
  var endpoint = $panel.data("endpoint");
  var inputParam = $panel.data("input-param") || "id";
  var targetPanel = $panel.data("target-panel") || "marc_editor_panel";
  var protectedTags = $panel.data("protected-tags") || [];
  var sidebarSelector = $panel.data("sidebar");

  var $input = $panel.find(".external-fetch-input");
  var $button = $panel.find(".external-fetch-button");
  var $loader = $panel.find(".loader");

  function searchExternalSource() {
    var term = $input.val();
    var model = $("#" + targetPanel).attr("data-editor-model");
    var isNew = $("body").hasClass("new");

    if (!term) return;

    var requestData = { new: isNew };
    requestData[inputParam] = term;

    $.ajax({
      type: "GET",
      url: "/admin/" + model + "/" + endpoint + ".json",
      data: requestData,
      beforeSend: function() { $loader.show(); },
      complete: function() { $loader.hide(); },
      success: function(response) {
        var data = response.data || response;
        _marc_editor_update_from_json(data, protectedTags, true);
        marc_editor_show_panel(targetPanel);
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

  if (sidebarSelector) {
    $(sidebarSelector).on("click", function() {
      marc_editor_show_panel($panel.attr("id"));
      $panel.children("div.tab_panel").show();
    });
  }

  $button.on("click", function(e) {
    e.preventDefault();
    searchExternalSource();
  });

  $input.on("keydown", function(e) {
    if ((e.keyCode || e.which) === 13) {
      e.preventDefault();
      searchExternalSource();
    }
  });
}

$(document).ready(function() {
  $(".external-fetch-panel").each(function() {
    initExternalFetchPanel($(this));
  });
});