module StatisticsHelper
  def sigla_pie_colors
    {
      fillColor: "rgba(220,220,220,0.2)",
      backgroundColor: [
        "#ff0000",
        "#0066cc",
        "#ffcc00",
        "#009933",
        "#ff6600",
        "#ff6699",
        "#33cc00",
        "#4db8ff",
        "#cc9966",
        "#d11aff",
        "#ffff1a",
        "#85adad",
        "#b6b6e2"
      ],
      hoverBackgroundColor: [
        "#cc0000",
        "#004d99",
        "#cca300",
        "#006622",
        "#cc5200",
        "#ff3377",
        "#269900",
        "#1aa3ff",
        "#bf8040",
        "#b800e6",
        "#e6e600",
        "#669999",
        "#9898d6"
      ],
      strokeColor: "#1B4E7D",
      pointColor: "rgba(220,220,220,1)",
      pointStrokeColor: "#fff",
      pointHighlightFill: "#fff",
      pointHighlightStroke: "rgba(220,220,220,1)"
    }
  end
end
