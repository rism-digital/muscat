module ActiveAdmin
  module Views
    class Footer < Component

      def build
        super :id => "footer"                                                    
        super :style => "text-align: left;"                                     

        div do                                                                   
          small "Muscat #{Date.today.year} #{Git::VERSION}"                                       
        end
      end

    end
  end
end