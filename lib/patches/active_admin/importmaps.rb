module ActiveAdmin
  module Views
    module Head
      def build_active_admin_head
        within super do
          text_node javascript_include_tag("edtf_subfield", defer: true)
          text_node javascript_include_tag("active_admin_mention_input", defer: true)
        end
      end
    end
  end
end

ActiveAdmin::Views::Pages::Base.send :prepend, ActiveAdmin::Views::Head
