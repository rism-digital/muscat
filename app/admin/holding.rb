ActiveAdmin.register Holding do
  
  # Hide the menu
  menu false

  config.clear_action_items!
  # Remove mass-delete action
  batch_action :destroy, false

  breadcrumb do
    active_admin_muscat_breadcrumb
  end
  
  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do        
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
      @editor_validation = EditorValidation.get_default_validation(@item)
      @page_title = "#{I18n.t(:edit)} #{@item.formatted_title}"
      
      if cannot?(:edit, @item)
        redirect_to admin_holding_path(@item), :flash => { :error => I18n.t(:"active_admin.access_denied.message") }
      end

      # Force marc to load
      begin
        @item.marc.load_source(true)
      rescue ActiveRecord::RecordNotFound
        flash[:error] = I18n.t(:unloadable_record)
        AdminNotifications.notify("Holding #{@item.id} seems unloadable, please check", @item).deliver_now
        redirect_to admin_holding_path @item
        return
      end
      
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
      
      # Trigger a reindex of the parent source so this holding gets de-indexed
      Delayed::Job.enqueue(ReindexForeignRelationsJob.new(source, [{class: Source, id: @holding.source_id}]))

      begin 
        @holding.destroy!
      rescue ActiveRecord::RecordNotDestroyed
        flash[:error] = "This Holding #{@holding.id} is part of a composite volume, please delete 973 in the Holding"
      end

      if can?(:edit, source)
        redirect_to edit_admin_source_path(source)
      else
        redirect_to admin_source_path(source)
      end
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
      
      # Apply the right default file
      default_file = "default.marc"
      default_file = "libretto_holding_default.marc" if source.get_record_type == :libretto_edition
      default_file = "treatise_holding_default.marc" if source.get_record_type == :theoretica_edition

      new_marc = MarcHolding.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/holding/#{default_file}")))
      new_marc.load_source false # this will need to be fixed
      @holding.marc = new_marc

      @editor_profile = EditorConfiguration.get_default_layout @holding
      @editor_validation = EditorValidation.get_default_validation(@holding)
      # Override the default to have a better name
      @page_title = I18n.t('new_holding_page')
      #To transmit correctly @item we need to have @source initialized
      @item = @holding
    end
  
  end
  
  collection_action :render_embedded, method: :post do    
    @item = Holding.find(params[:object_id] )#params[:object_id] )
    
    begin
      @item.marc.load_source(true)
    rescue ActiveRecord::RecordNotFound
      puts "Could not properly load MarcHolding #{@item.id}"
    end
    
    @editor_profile = EditorConfiguration.get_show_layout @item
    
    render :template => 'marc_show/show_preview', :locals => {:holdings => true }
  
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
  filter :source_id_contains, :label => proc{I18n.t(:filter_source_id)}, :as => :string

  
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "Holding").collect {|c| [c.lib_siglum, "folder_id:#{c.id}"]}}
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_id), :id    
    column (I18n.t :name) {|h| h.formatted_title}
    active_admin_muscat_actions( self, false ) # Hide the "view" button
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

  
  ##########
  ## Edit ##
  ##########
  
  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
  end
  
  form :partial => "editor/edit_wide"
  
end
