ActiveAdmin.register ActiveAdmin::Comment, :as => "Comment" do
  
  # Remove all action items
  config.clear_action_items!
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => comment }
  end
  
end