$(function () {
  $("canvas[data-chart]").each(function () {
    var $canvas = $(this);
    var raw = $canvas.attr("data-chart");
    if (!raw) {
      return;
    }
    try {
      var data = JSON.parse(raw);
      var type = $canvas.attr("data-chart-type") || "bar";
      var optionsRaw = $canvas.attr("data-chart-options");
      var options = {};
      if (optionsRaw) {
        try {
          options = JSON.parse(optionsRaw);
        } catch (e) {
          if (window.console && console.warn) {
            console.warn("Failed to parse chart options", e);
          }
        }
      }
      new Chart($canvas, { type: type, data: data, options: options });
    } catch (e) {
      if (window.console && console.warn) {
        console.warn("Failed to parse chart data", e);
      }
    }
  });
});
