ActiveAdmin.register Folder do
  
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
      params.permit!
    end
    
  end
  
  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(params[:id], Folder, :folder_items))
    redirect_to resource_path(params[:id]), notice: I18n.t(:reindex_job, scope: :folders, id: job.id)
  end
  
  #action_item :publish, only: :show do
  #  link_to 'Publish', publish_admin_folder_path(folder)
  #end
  
  member_action :publish, method: :get do
    job = Delayed::Job.enqueue(PublishFolderJob.new(params[:id]))
    redirect_to resource_path(params[:id]), notice: I18n.t(:publish_job, scope: :folders, id: job.id)
  end
 
  member_action :unpublish, method: :get do
    job = Delayed::Job.enqueue(PublishFolderJob.new(params[:id], unpublish: true))
    redirect_to resource_path(params[:id]), notice: I18n.t(:unpublish_job, scope: :folders, id: job.id)
  end
 
  member_action :make_catalogue, method: :get do
    # A bit contorted here: only work_editors can make a Publication into catalogs
    if !can?(:edit, Work)
      redirect_to collection_path, :flash => {error: I18n.t(:"active_admin.access_denied.message")}
      return
    end

    job = Delayed::Job.enqueue(MakePublicationsCataloguesFromFolder.new(params[:id]))
    redirect_to resource_path(params[:id]), notice: I18n.t(:make_catalogue, scope: :folders, id: job.id)
  end

  member_action :reset_expiration, method: :get do
    begin
      f = Folder.find(params[:id])
    rescue
      redirect_to collection_path, :flash => {error: I18n.t(:not_found, scope: :folders, id: params[:id])}
      return
    end

    if !can?(:edit, f)
      redirect_to collection_path, :flash => {error: I18n.t(:"active_admin.access_denied.message")}
      return
    end

    f.save

    redirect_to resource_path(params[:id]), notice: I18n.t(:"folders.resetted", date: f.delete_date.to_date.to_s)
  end

  ## Shows a page so the user can select the folder name
  member_action :export_folder, :method => :get do
    begin
      f = Folder.find(params[:id])
    rescue
      # This should really never happen
      redirect_to collection_path, :flash => {error: I18n.t(:not_found, scope: :folders, id: params[:id])}
      return
    end

    if !f.folder_items || f.folder_items.empty?
      redirect_to resource_path(params[:id]), :flash => {error:I18n.t(:folder_empty, scope: :folders)}
      return
    end

    if f.folder_items.count > 25000
      redirect_to resource_path(params[:id]), :flash => {error: I18n.t(:export_limit, scope: :folders, max: 25000, count: f.folder_items.count)}
      return
    end

    format = params.include?(:csv) ? :csv : :xml

    job = Delayed::Job.enqueue(ExportRecordsJob.new(:folder, {id: params[:id], email: current_user.email, format: format}))
    redirect_to resource_path(params[:id]), notice: I18n.t(:export_started, scope: :folders, email: current_user.email, job: job.id)
  end 

  member_action :validate_folder, method: :get do
    begin
      f = Folder.find(params[:id])
    rescue
      # This should really never happen
      redirect_to collection_path, :flash => {error: I18n.t(:not_found, scope: :folders, id: params[:id])}
      return
    end

    if !f.folder_items || f.folder_items.empty?
      redirect_to resource_path(params[:id]), :flash => {error:I18n.t(:folder_empty, scope: :folders)}
      return
    end

    if f.folder_type != "Source"
      redirect_to resource_path(params[:id]), :flash => {error:I18n.t(:folder_not_source, scope: :folders)}
      return
    end

    job = Delayed::Job.enqueue(FolderValidationReportJob.new(f.id, current_user.id))
    redirect_to resource_path(params[:id]), notice: I18n.t(:validation_started, scope: :folders, email: current_user.email, job: job.id)
  end

  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  

  index :download_links => false do |ad|
    selectable_column
    column (I18n.t :filter_wf_stage) {|folder| status_tag(folder.is_published?,
      label: I18n.t('status_codes.' + (folder.is_published? ? "published" : "inprogress"), locale: :en))} 
    id_column
    column (I18n.t :filter_name), :name, sortable: :name
    column (I18n.t :filter_folder_type), :folder_type
    column (I18n.t :filter_owner), sortable: "users.name" do |folder|
      folder.user.name
    end

    column (I18n.t "folders.expires"), sortable: :delete_date do |r| 
      r.delete_date.to_date.to_s
    end

    column (I18n.t "folders.items") {|folder| folder.folder_items.count}
    actions
  end
  
  sidebar :actions, :only => :index do
    render :partial => "activeadmin/filter_workaround"
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
    
    panel folder.folder_type.pluralize, :class => "muscat_panel"  do
      
      fitems = folder.folder_items
      
      paginated_collection(fitems.page(params[:src_list_page]).per(10), param_name: 'src_list_page',  download_links: false) do
        table_for(collection) do |cr|
          column ("Name") {|fitem| fitem.item ? fitem.item.name : "Item Deleted"}
          column ("Created at") {|fitem| fitem.item ? fitem.item.created_at : "n.a."}
          column ("Updated at") {|fitem| fitem.item ? fitem.item.updated_at : "n.a."}
          column ("Id") {|fitem| fitem.item ? fitem.item.id : "n/a, was #{fitem.item_id}"}
          column "" do |fitem|
            if fitem.item
              link_to "View", controller: fitem.item.class.to_s.pluralize.underscore.downcase.to_sym, action: :show, id: fitem.item.id
            end
          end
        end
      end
    end
    
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => folder }
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
