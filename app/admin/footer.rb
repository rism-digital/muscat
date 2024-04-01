module ActiveAdmin
  module Views
    class Footer < Component

      def build(namespace)
        super :id => "footer"
        super :style => "text-align: left;"
         
        tab = @arbre_context.assigns[:tab_id_for_footer] rescue tab = "global"

        div do
          small "Muscat #{Date.today.year} #{Git::VERSION} (#{Git::REVISION}) [#{tab}] |" 
          span do 
            link_to "Impressum", "/impressum.html"
          end
        end
      end

    end
  end
end
