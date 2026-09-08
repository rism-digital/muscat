module ActiveAdmin
  module Views
    class Footer < Component
      def build(*)
        super id: "footer", style: "text-align: left;"

        tab = controller.view_assigns["tab_id_for_footer"] || "global"

        div do
          small do
            text_node "Muscat #{Date.today.year} #{Git::VERSION} (#{Git::REVISION}) | "
            text_node "Tab: #{tab} "

            span id: "tab-debug" do
              text_node ""
            end

            text_node " | "
            link_to "Impressum", "/impressum.html"
          end
        end
      end
    end
  end
end