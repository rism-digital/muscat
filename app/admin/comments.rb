ActiveAdmin.register ActiveAdmin::Comment, :as => "Comment" do
  
  # Remove all action items
  config.clear_action_items!
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => comment }
  end
 
  index do
    column :resource_type
    column :author_type
    column :resource
    column :author
    column "Text", :body do |comment|
      truncate(comment.body, omision: "...", length: 80)
    end
    column :created_at
    actions
  end
end
