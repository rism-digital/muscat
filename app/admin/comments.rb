ActiveAdmin.register ActiveAdmin::Comment, :as => "Comment" do
  
  after_create do |comment|
    CommentNotifications.new_comment(comment).deliver_now
  end
  
  # Remove all action items
  config.clear_action_items!
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => comment }
  end
  
  controller do    
    def index
			if params[:as] and params[:as] == "table"
				index!
			else
	      index! do |format|
	        a = ActiveAdmin::Comment.all
	        a = a.where("body LIKE '%#{params[:q][:body_contains]}%'") if params[:q] and params[:q][:body_contains]
	        a = a.where("author_id = #{params[:q][:author_id_eq]}") if params[:q] and params[:q][:author_id_eq]
	        a = a.where("resource_type = '#{params[:q][:resource_type_eq]}'") if params[:q] and params[:q][:resource_type_eq]
	        scope = a.select(:resource_id, :resource_type).distinct
	        @collection = scope.page(params[:page])
	      end
			end
    end
  end

  index as: :comment do |c|
    scope = ActiveAdmin::Comment.where("resource_id = #{c.resource_id}", "resource_type = #{c.resource_type}")
    comments = scope.page(1)
    table_for(comments, {:sortable =>false, :class => 'i'}) do
      column :created_at
      column :author
      column "Text", :body do |comment|
        truncate(comment.body, omision: "...", length: 80)
      end
    end
  end
  
  filter :body, :label => proc {I18n.t(:filter_comments)}, :as => :string
  filter :resource_type, :default => 'Source'
  filter :author_id, :label => proc {I18n.t(:filter_author)}, as: :select, 
         collection: proc {
           if current_user.has_any_role?(:editor, :admin)
             User.sort_all_by_last_name.map{|u| [u.name, "#{u.id}"]}
           else
             [[current_user.name, "#{current_user.id}"]]
           end
         }
         
end

