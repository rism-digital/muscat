module ActiveAdmin
  module Views
    module Head
      def build_active_admin_head
        within super do
          text_node javascript_importmap_tags("active_admin_importmaps")
        end
      end
    end
  end
end

ActiveAdmin::Views::Pages::Base.send :prepend, ActiveAdmin::Views::Head