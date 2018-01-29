ActiveAdmin.register Holding do
  
  # Hide the menu
  menu false

  config.clear_action_items!
  # Remove mass-delete action
  batch_action :destroy, false

  breadcrumb do
    active_admin_muscat_breadcrumb
  end
    
  action_item :view, only: :show, if: proc{ is_selection_mode? } do
    active_admin_muscat_select_link( person )
  end

  action_item :view, only: [:index, :show], if: proc{ is_selection_mode? } do
    active_admin_muscat_cancel_link
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
        
    def format_holding( holding )
      return "#{I18n.t(:edit)} #{holding.lib_siglum} [#{holding.id}]" if !holding.source
      return "#{I18n.t(:edit)} #{holding.lib_siglum} [#{holding.id}] in (#{holding.source.std_title} [#{holding.source.id}])"if !holding.source.composer || holding.source.composer.empty?
      return "#{I18n.t(:edit)} #{holding.lib_siglum} [#{holding.id}] in (#{holding.source.composer} [#{holding.source.id}])" if !holding.source.std_title || holding.source.std_title.empty?
      return "#{I18n.t(:edit)} #{holding.lib_siglum} [#{holding.id}] in (#{holding.source.composer} - #{holding.source.std_title} [#{holding.source.id}])"
    end
        
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
      @item = Holding.find(params[:id])
      @parent_object_id = @item.source.id
      @parent_object_type = "Source" #hardcoded for now
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_show_layout @item
      @page_title = format_holding(@item)
    end

    def destroy
      begin
        @holding = Holding.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Holding #{params[:id]})" }
        return
      end
      
      if cannot?(:destroy, @holding)
        flash[:error] = "Operation not allowed"
        redirect_to edit_admin_source_path(source)
        return
      end
      
      source = @holding.source
      
      @holding.destroy!
      redirect_to edit_admin_source_path(source)
    end

    def show
      begin
        @holding = Holding.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Holding #{params[:id]})"  }
        return
      end
      redirect_to edit_admin_source_path(@holding.source)
    end
   
    def index
      @results, @hits = Holding.search_as_ransack(params)
      
      index! do |format|
        @holdings = @results
        format.html
      end
    end
    
    def new
      if !params.include?(:source_id) || !params[:source_id]
        redirect_to admin_root_path, :flash => { :error => "PLEASE INCLUDE A SOURCE ID" }
        return
      end
      
      begin
        source = Source.find(params[:source_id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "Could not find source #{params[:source_id]}" }
        return
      end
      
      @holding = Holding.new
      source = Source.find(params[:source_id])
      @holding.source = source
      @parent_object_id = params[:source_id]
      @parent_object_type = "Source" #hardcoded for now
      
      new_marc = MarcHolding.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc"))
      new_marc.load_source false # this will need to be fixed
      @holding.marc = new_marc

      @editor_profile = EditorConfiguration.get_default_layout @holding
      # Override the default to have a better name
      @page_title = I18n.t('new_holding_page')
      #To transmit correctly @item we need to have @source initialized
      @item = @holding
    end
    
  end
  
  # Include the folder actions
  include FolderControllerActions
  
  include MarcControllerActions

  ###########
  ## Index ##
  ###########
  
  #scope :all, :default => true 
  #scope :published do |holdings|
  #  holdingds.where(:wf_stage => 'published')
  #end
  
  # Solr search all fields: "_equal"
  filter :lib_siglum_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "Holding").collect {|c| [c.lib_siglum, "folder_id:#{c.id}"]}}
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_id), :id    
    column (I18n.t :filter_lib_siglum), :lib_siglum
    active_admin_muscat_actions( self )
  end
  
  ##########
  ## Show ##
  ##########
  
  show :title => proc{ active_admin_holding_show_title(@item) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    @item = @arbre_context.assigns[:item]
    if @item.marc_source == nil
      render :partial => "marc_missing"
    else
      render :partial => "marc/show"
    end
    active_admin_user_wf( self, holding )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => @arbre_context.assigns[:item] }
  end
 
  
begin  
  sidebar I18n.t(:search_sources), :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end

end
  
  ##########
  ## Edit ##
  ##########
  
  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
  end
  
  form :partial => "editor/edit_wide"
  
end
