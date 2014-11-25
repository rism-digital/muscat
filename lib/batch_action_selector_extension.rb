#See  http://stackoverflow.com/questions/4470108/when-monkey-patching-a-method-can-you-call-the-overridden-method-from-the-new-i

# Use this patch to have buttons in the topbar aligned to the batch actions

=begin
module ActiveAdmin
  module BatchActions
    
    class BatchActionSelector
      old_build_drop_down = instance_method(:build_drop_down)

       define_method(:build_drop_down) do
          old_build_drop_down.bind(self).()
          
          ul :class => "scopes table_tools_segmented_control", :style => "" do
            li :class => "scope" do
              a :href => "#", :class => "table_tools_button" do
                name = "peppo"
                I18n.t("active_admin.index_list.padul", :default => "test")
              end
            end
          end

       end
    
     end
  end
end
=end
