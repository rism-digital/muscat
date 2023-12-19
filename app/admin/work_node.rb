include Triggers
  
ActiveAdmin.register WorkNode do

  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_work_nodes)}, :if => proc{ can? :edit, WorkNode  }

  # Remove mass-delete action
  batch_action :destroy, false
  include MergeControllerActions
  
  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100]
  
  collection_action :autocomplete_work_title, :method => :get

  collection_action :gnd, method: :get do
    respond_to do |format|
        format.json { render json: WorkNode.get_gnd(params[:gnd_input])  }
    end
  end

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :work_node, :title, :extra_data => [:title], :string_boundary => true
    
    after_destroy :check_model_errors
    before_create do |item|
      item.user = current_user
    end
    
    def action_methods
      return super - ['new', 'edit', 'destroy'] if is_selection_mode?
      super
    end
    
    def check_model_errors(object)
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end
    
    def permitted_params
      params.permit!
    end
    
    def edit
      flash.now[:error] = params[:validation_error] if params[:validation_error]
      @item = WorkNode.find(params[:id])
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_default_layout @item
      @editor_validation = EditorValidation.get_default_validation(@item)
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"

      @restricted=""
    end
    
    def show
      begin
        @item = @work_node = WorkNode.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (WorkNode #{params[:id]})" }
        return
      end
      @editor_profile = EditorConfiguration.get_show_layout @work_node
      @prev_item, @next_item, @prev_page, @next_page = WorkNode.near_items_as_ransack(params, @work_node)
      
      @jobs = @work_node.delayed_jobs
      
      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml(@item.updated_at, @item.versions) }
      end
    end
    
    def index
      @results, @hits = WorkNode.search_as_ransack(params)
      index! do |format|
        @work_nodes = @results
        format.html
      end
    end
    
    def new
      @work_node = WorkNode.new
      
      new_marc = MarcWorkNode.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/work_node/default.marc")))
      new_marc.load_source false # this will need to be fixed
      @work_node.marc = new_marc
      
      @editor_profile = EditorConfiguration.get_default_layout @work_node
      @editor_validation = EditorValidation.get_default_validation(@work_node)
      # Since we have only one default template, no need to change the title
      #@page_title = "#{I18n.t('active_admin.new_model', model: active_admin_config.resource_label)} - #{@editor_profile.name}"
      #To transmit correctly @item we need to have @source initialized
      @item = @work_node
    end

  end
  
  # Include the MARC extensions
  include MarcControllerActions
  
  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(params[:id], WorkNode, :referring_sources))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :title_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "WorkNode").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_wf_stage) {|work_node| status_tag(work_node.wf_stage,
      label: I18n.t('status_codes.' + (work_node.wf_stage != nil ? work_node.wf_stage : ""), locale: :en))} 
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_title), :title
    column (I18n.t :filter_sources), :src_count_order, sortable: :src_count_order do |element|
			all_hits = @arbre_context.assigns[:hits]
			active_admin_stored_from_hits(all_hits, element, :src_count_order)
		end
    active_admin_muscat_actions( self )
  end
  
  sidebar :actions, :only => :index do
    render :partial => "activeadmin/filter_workaround"
    render :partial => "activeadmin/section_sidebar_index"
  end
  
  # Include the folder actions
  include FolderControllerActions
  
  ##########
  ## Show ##
  ##########
  
  show :title => proc{ active_admin_auth_show_title( @item.title, nil, @item.id) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    
    render('jobs/jobs_monitor')
    
    @item = @arbre_context.assigns[:item]
    if @item.marc_source == nil
      render :partial => "marc/missing"
    else
      render :partial => "marc/show"
    end
    active_admin_embedded_source_list( self, work_node, !is_selection_mode? )
    active_admin_user_wf( self, work_node )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => work_node }
  end
  
  sidebar :folders, :only => :show do
    render :partial => "activeadmin/section_sidebar_folder_actions", :locals => { :item => work_node }
  end

  ##########
  ## Edit ##
  ##########
  
  form :partial => "editor/edit_wide"
  
  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
	end
  
end
