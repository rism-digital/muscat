ActiveAdmin.register Folder do
  include FolderActions::BulkMarc
  include FolderActions::Ownership
  include FolderActions::Publishing
  include FolderActions::Exports
  include FolderActions::Maintenance
  
  menu :priority => 7, :label => proc {I18n.t(:menu_folders)}

  # Remove mass-delete action
  batch_action :destroy, false
  
  # Remove all action items
  config.clear_action_items!
  
  # Remove creation option (only possible from lists)
  actions :all, :except => [:new]
  
  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
        
    after_destroy :check_model_errors
    before_create do |item|
      item.user = current_user
    end
    
    def scoped_collection
      
      #super.joins(
      #  %(LEFT OUTER JOIN folder_items
      #      ON folders.id = folder_items.folder_id))
      #  .select("folders.*, COUNT(folder_items.id) AS folder_items_count")
      #  .group("folders.id")
      end_of_association_chain.includes([:user])
    end


    def show
      begin
        @folder = Folder.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Folder #{params[:id]})" }
        return
      end
      @jobs = @folder.delayed_jobs
    end
    
    def check_model_errors(object)
      
      # Look in the saved filters for this controller
      # relative to the folder type of the deleted folder
      # if it was filtered by folder. If it was remove it
      controller =  object.folder_type.underscore.downcase.pluralize
      if session[:last_search_filter] && session[:last_search_filter][controller]
        params_q =  session[:last_search_filter][controller]
        if params_q.include?(:id_with_integer)
          params_q.delete(:id_with_integer)
        end
      end
      
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end
    
    def permitted_params
      params.permit(folder: [:name])
    end
    
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :name, :label => proc {I18n.t(:filter_name)}, :as => :string
  filter :folder_type, :label => proc {I18n.t(:filter_folder_type)}, :as => :string
  

=begin
  filter :wf_owner, :label => proc {I18n.t(:filter_owner)}, as: :select, 
         collection: proc {
           if current_user.has_any_role?(:editor, :admin)
             User.sort_all_by_last_name.map{|u| [u.name, "#{u.id}"]}
           else
             [[current_user.name, "#{current_user.id}"]]
           end
         } 
=end
 filter :wf_owner, :label => proc {I18n.t(:filter_owner)}, as: :flexdatalist, data_path: proc{list_for_filter_admin_users_path()}

  index :download_links => false do |ad|
    selectable_column
    column (I18n.t :filter_wf_stage) do |folder|
      stage = folder.publication_status
      if stage
        status_tag(stage, label: I18n.t("status_codes.#{stage}", locale: :en),
          class: stage == :mixed ? "warning" : nil)
      end
    end
    id_column
    column (I18n.t :filter_name), :name, sortable: :name
    column (I18n.t :filter_folder_type), :folder_type
    column (I18n.t :filter_owner), sortable: "users.name" do |folder|
      folder.user.name
    end

    column (I18n.t "created_at"), sortable: :created_at do |r| 
      r.created_at
    end

    column (I18n.t "folders.expires"), sortable: :delete_date do |r| 
      r.delete_date.to_date.to_s
    end

    column (I18n.t "folders.items") {|folder| folder.folder_items.count}

    actions
  end
  
  sidebar :actions, :only => :index do
    render :partial => "activeadmin/section_sidebar_index"
  end

  sidebar :help, :only => :index do
    render :partial => "folders_help_index"
  end
  
  ##########
  ## Show ##
  ##########
  
  show do
    active_admin_navigation_bar( self )
    
    render('jobs/jobs_monitor')
    
    attributes_table do
      row (I18n.t :filter_name) { |r| r.name }
      row (I18n.t :created_at) {|folder| folder.created_at}
      row (I18n.t "folders.expires") { |r| r.delete_date.to_date.to_s }
      row (I18n.t :filter_folder_type) { |r| r.folder_type }
      row (I18n.t :filter_owner) {|folder| folder.user.name}
    end
    
    active_admin_folder_item_table(self, folder)
    
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => folder }
    render partial: "admin/folders/sidebar_actions", locals: { folder: folder }
  end

  sidebar :help, :only => [:show] do
    render :partial => "folders_help_show"
  end

  ##########
  ## Edit ##
  ##########

  form do |f|
    f.inputs do
      f.input :name, :label => (I18n.t :filter_name)
    end
  end
  
  sidebar :actions, :only => [:edit, :new, :update] do
    render :partial => "activeadmin/section_sidebar_edit", :locals => { :item => folder }
  end
  
end
