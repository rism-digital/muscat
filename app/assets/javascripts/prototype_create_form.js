// app/assets/javascripts/active_admin/prototype_create_form.js

(function ($) {
  function setupPrototypeCreateForms() {
    $(".prototype-create-form").each(function () {
      var $form = $(this);
      var $input = $form.find(".prototype-create-source-id");
      var $submit = $form.find(".prototype-create-submit");
      var $message = $form.find(".prototype-create-message");

      if (!$input.length || !$submit.length || !$message.length) return;
      if ($form.data("prototype-create-bound")) return;

      $form.data("prototype-create-bound", true);

      var timeout = null;
      var currentRequest = null;

      function disableSubmit() {
        $submit.prop("disabled", true).css({
          opacity: "0.5",
          cursor: "not-allowed"
        });
      }

      function enableSubmit() {
        $submit.prop("disabled", false).css({
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
          .text($input.data("invalid-message") || "Invalid selection")
          .css("color", "red")
          .show();
      }

      function setValid(title) {
        enableSubmit();
        $input.css("border-color", "green");
        $message
          .text(title || "Valid selection")
          .css("color", "green")
          .show();
      }

      function checkSourceId() {
        var sourceId = $.trim($input.val());

        if (!sourceId) {
          setEmpty();
          return;
        }

        var checkUrl = $input.data("check-url");
        var url = checkUrl.replace(":id", encodeURIComponent(sourceId));

        if (currentRequest) currentRequest.abort();

        currentRequest = $.ajax({
          url: url,
          method: "GET",
          dataType: "json"
        })
          .done(function (data) {
            if (data.valid === true || data.is_inventory === true || data.is_catalog === true) {
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

      $input.on("input.prototypeCreate paste.prototypeCreate", function () {
        clearTimeout(timeout);
        timeout = setTimeout(checkSourceId, 300);
      });

      setEmpty();
    });
  }

  $(document).ready(setupPrototypeCreateForms);
  $(document).on("turbo:load", setupPrototypeCreateForms);
})(jQuery);