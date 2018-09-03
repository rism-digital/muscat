ActiveAdmin.register ActiveAdmin::Comment, :as => "Comment" do
  
  after_create do |comment|
    CommentNotifications.new_comment(comment).deliver_now
  end
  
  # Remove all action items
  config.clear_action_items!
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => comment }
  end
	
	scope :admin
	scope("Archived") { |scope| scope.where(namespace: :archived) }
	scope :all
  
	# Custom action for archiving comments - done with namespace attribute (for now)
	# param[:do] true/false for archive or unarchive a comment
	# redirection to the comments/index
  member_action :archive, method: :get do
	  if request.get? && can?(:manage, resource)
			puts params
			value = (params[:do] && params[:do] == "false") ? :admin : :archived
	    resource.update_attributes! namespace: value || {}
			resource.save!
	    redirect_to collection_path, notice: "Item successfully (un-)archived"
		else
	  	redirect_to collection_path, error: "Item cannot be (un-)archived"
		end
  end
	
  controller do   
    def index
			if params[:as] and params[:as] == "table"
				index!
			else
	      index! do |format|
	        a = ActiveAdmin::Comment.all
	        a = a.where("namespace = '#{params[:scope]}'") if params[:scope] && params[:scope] != "all"
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
      column (I18n.t :filter_creation_date), :created_at
      column (I18n.t :filter_author), :author
      column (I18n.t :filter_comment), :body do |comment|
        link_to truncate(comment.body, omision: "...", length: 80), admin_comment_path(comment)
      end
	    column (I18n.t :filter_wf_stage) {|comment| status_tag(comment.namespace, (comment.namespace == "admin" ? :ok : ""))} 
		  column "" do |comment|
				if comment.namespace == "archived"
					link_to (I18n.t :unarchive), archive_admin_comment_path(comment, :do => false)
				else
					link_to (I18n.t :archive), archive_admin_comment_path(comment, :do => true)
				end
		  end
    end
  end
  
  filter :body, :label => proc {I18n.t(:filter_comment)}, :as => :string
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

