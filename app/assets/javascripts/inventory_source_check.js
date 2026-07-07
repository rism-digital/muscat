// app/assets/javascripts/active_admin/inventory_source_check.js

(function ($) {
  function setupInventorySourceCheck() {
    var $input = $("#inventory-source-id");
    var $submit = $("#create-inventory-submit");
    var $message = $("#inventory-source-message");

    if (!$input.length || !$submit.length || !$message.length) return;

    var timeout = null;
    var currentRequest = null;

    function disableSubmit() {
      $submit
        .prop("disabled", true)
        .css({
          opacity: "0.5",
          cursor: "not-allowed"
        });
    }

    function enableSubmit() {
      $submit
        .prop("disabled", false)
        .css({
          opacity: "1",
          cursor: "pointer"
        });
    }

    function setEmpty() {
      disableSubmit();

      $input.css("border-color", "");
      $message.hide().text("").css("color", "");
    }

    function setInvalid() {
      disableSubmit();

      $input.css("border-color", "red");
      $message
        .text("Please select an inventory")
        .css("color", "red")
        .show();
    }

    function setValid(title) {
    enableSubmit();

    $input.css("border-color", "green");
    $message
        .text(title)
        .css("color", "green")
        .show();
    }

    function checkSourceId() {
      var sourceId = $.trim($input.val());

      if (!sourceId) {
        setEmpty();
        return;
      }

      var url = $input.data("inventory-check-url").replace(
        ":id",
        encodeURIComponent(sourceId)
      );

      if (currentRequest) {
        currentRequest.abort();
      }

      currentRequest = $.ajax({
        url: url,
        method: "GET",
        dataType: "json"
      })
        .done(function (data) {
        if (data.is_inventory === true) {
            setValid(data.title);
        } else {
            setInvalid();
        }
        })
        .fail(function (_xhr, status) {
          if (status === "abort") return;
          setInvalid();
        });
    }

    $input.off("input.inventorySourceCheck paste.inventorySourceCheck");

    $input.on("input.inventorySourceCheck paste.inventorySourceCheck", function () {
      clearTimeout(timeout);
      timeout = setTimeout(checkSourceId, 300);
    });

    setEmpty();
  }

  $(document).ready(setupInventorySourceCheck);
  $(document).on("turbo:load", setupInventorySourceCheck);
})(jQuery);