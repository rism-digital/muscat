ActiveAdmin.register Institution do
  
  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_institutions)}

  # Remove mass-delete action
  batch_action :destroy, false
  
  collection_action :autocomplete_institution_siglum, :method => :get
  collection_action :autocomplete_institution_name, :method => :get

  breadcrumb do
    active_admin_muscat_breadcrumb
  end
    
  action_item :view, only: :show, if: proc{ is_selection_mode? } do
    active_admin_muscat_select_link( institution )
  end

  action_item :view, only: [:index, :show], if: proc{ is_selection_mode? } do
    active_admin_muscat_cancel_link
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :institution, [:siglum, :name], :display_value => :autocomplete_label_siglum, :extra_data => [:siglum, :name], :required => :siglum
    autocomplete :institution, :name, :display_value => :autocomplete_label_name, :extra_data => [:siglum, :name]
    
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
      @item = Institution.find(params[:id])
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_applicable_layout @item
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"
    end
    
    def show
      begin
        @item = @institution = Institution.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Institution #{params[:id]})" }
        return
      end
      @editor_profile = EditorConfiguration.get_show_layout @institution
      @prev_item, @next_item, @prev_page, @next_page = Institution.near_items_as_ransack(params, @institution)
      
      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml(@item.updated_at, @item.versions) }
      end
    end
   
    def index
      @results = Institution.search_as_ransack(params)
      
      index! do |format|
        @institutions = @results
        format.html
      end
    end
    
    def new
      @institution = Institution.new
      
      new_marc = MarcInstitution.new(File.read("#{Rails.root}/config/marc/#{RISM::BASE}/institution/default.marc"))
      new_marc.load_source false # this will need to be fixed
      @institution.marc = new_marc

      @editor_profile = EditorConfiguration.get_applicable_layout @institution
      # Since we have only one default template, no need to change the title
      #@page_title = "#{I18n.t('active_admin.new_model', model: active_admin_config.resource_label)} - #{@editor_profile.name}"
      #To transmit correctly @item we need to have @source initialized
      @item = @institution
    end
    
  end
  
  # Include the folder actions
  include FolderControllerActions
  
  include MarcControllerActions
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "Institution").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_siglum), :siglum
    column (I18n.t :filter_location_and_name), :name
    column (I18n.t :filter_place), :place
    column (I18n.t :filter_sources), :src_count
    active_admin_muscat_actions( self )
  end
  
  ##########
  ## Show ##
  ##########
  
  show :title => proc{ active_admin_source_show_title( @item.name, @item.siglum, @item.id) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    @item = @arbre_context.assigns[:item]
    if @item.marc_source == nil
      render :partial => "marc_missing"
    else
      render :partial => "marc/show"
    end
    active_admin_embedded_source_list( self, institution, params[:qe], params[:src_list_page], !is_selection_mode? )
    active_admin_user_wf( self, institution )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar I18n.t(:search_sources), :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end

  ##########
  ## Edit ##
  ##########
  
  sidebar :sections, :only => [:edit, :new] do
    render("editor/section_sidebar") # Calls a partial
  end
  
  form :partial => "editor/edit_wide"

end
