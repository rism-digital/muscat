module ActiveAdmin
  module Views
    class Footer < Component

      def build(param)
        super :id => "footer"
        super :style => "text-align: left;"

        div do
          small "Muscat #{Date.today.year} #{Git::VERSION} (#{Git::REVISION}) | " 
          span do 
            link_to "Impressum", "/impressum.html"
          end
        end
      end

    end
  end
end
