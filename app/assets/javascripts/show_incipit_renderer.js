(function(window, document, $) {
  "use strict";

  if (!$) {
    return;
  }

  function buildPae($element) {
    var clef = $element.data("clef") || "";
    var keysig = $element.data("keysig") || "";
    var key = $element.data("key") || "";
    var timesig = $element.data("timesig") || "";
    var notation = $element.data("notation") || "";

    return [
      "@clef:" + clef,
      "@keysig:" + keysig,
      "@key:" + key,
      "@timesig:" + timesig,
      "@data: " + notation
    ].join("\n");
  }

  function renderWidth($element) {
    var parent_class = $element.data("width-parent");

    var $table = $element.parents("." + parent_class).first();
    if ($table.length) {
      return Math.max($table.width() - 250, 100);
    }

    return Math.max($element.width(), 100);
  }

  function renderElement(element) {
    var $element = $(element);

    if ($element.data("music-rendered")) {
      return;
    }

    var type = $element.data("render-type");
    var source;
    var width = renderWidth($element);
console.log(width)
    if (type === "mei") {
      source = $element.data("render-source");
    } else if (type === "pae") {
      source = buildPae($element);
    } else {
      return;
    }

    if (typeof window.render_music !== "function") {
      return;
    }

    window.render_music(source, type, $element, width);
    $element.data("music-rendered", true);
  }

  function renderAll(context) {
    var $context = context ? $(context) : $(document);
    $context.find(".js-music-render[data-render-music='true']").each(function() {
      renderElement(this);
    });
  }

  function bindToggle() {
    $(document).on("click", ".js-toggle-pae", function(event) {
      event.preventDefault();

      var targetId = $(this).data("toggle-target");
      if (!targetId) {
        return;
      }

      $("#" + targetId).toggle();
    });
  }

  function boot() {
    bindToggle();
    renderAll(document);
  }

  $(document).ready(boot);

  $(document).on("turbolinks:load", function() {
    renderAll(document);
  });

})(window, document, window.jQuery);
