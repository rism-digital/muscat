module ActiveAdmin
  module Views
    class Footer < Component

      def build(namespace)
        super :id => "footer"
        super :style => "text-align: left;"
         
        tab = @arbre_context.assigns[:tab_id_for_footer] rescue tab = "global"

        div do
          small "Muscat #{Date.today.year} #{Git::VERSION} (#{Git::REVISION}) |" 

          small do
            text_node "Tab: #{tab} "
            span id: "tab-debug" do
              text_node ""
            end
          end

          small " |" 

          span do 
            link_to "Impressum", "/impressum.html"
          end

        end
      end

    end
  end
end
