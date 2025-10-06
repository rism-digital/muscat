ActiveAdmin.register InventoryItem do
  collection_action :autocomplete_intentory_item_id, :method => :get

  # Hide the menu
  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_inventory_items)}, :if => proc{ can?(:update, InventoryItem)}

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
    
    autocomplete :inventory_item, :id, {:display_value => :autocomplete_label , :extra_data => [:title, :composer], :exact_match => true, :solr => false}

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
      @item = InventoryItem.find(params[:id])
      @parent_object_id = @item.source.id
      @parent_object_type = "Source" #hardcoded for now
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_show_layout @item
      @editor_validation = EditorValidation.get_default_validation(@item)
      @page_title = "#{I18n.t(:edit)} #{@item.formatted_title}"
      @total_items = @item.source.inventory_items.count
      
      # FIXME
      #if cannot?(:edit, @item)
      #  redirect_to admin_holding_path(@item), :flash => { :error => I18n.t(:"active_admin.access_denied.message") }
      #end

      # Force marc to load
      begin
        @item.marc.load_source(true)
      rescue ActiveRecord::RecordNotFound
        flash[:error] = I18n.t(:unloadable_record)
        AdminNotifications.notify("Inventory Item #{@item.id} seems unloadable, please check", @item).deliver_now
        redirect_to admin_inventory_item_path @item
        return
      end
      
    end

    def destroy
      begin
        @inventory_item = InventoryItem.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Inventory Item #{params[:id]})" }
        return
      end
      
      if cannot?(:destroy, @inventory_item)
        flash[:error] = "Operation not allowed"
        redirect_to edit_admin_source_path(source)
        return
      end
      
      source = @inventory_item.source
      
      ## FIXME DO WE NEED THIS
      Delayed::Job.enqueue(ReindexForeignRelationsJob.new(source, [{class: Source, id: @inventory_item.source_id}]))

      begin 
        @inventory_item.destroy!
      rescue ActiveRecord::RecordNotDestroyed
        flash[:error] = "FIXME #{@inventory_item.id}"
      end

      if can?(:edit, source)
        redirect_to edit_admin_source_path(source)
      else
        redirect_to admin_source_path(source)
      end
    end

    def show
      begin
        @item = @inventory_item = InventoryItem.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Inventory Item #{params[:id]})" }
        return
      end
      @editor_profile = EditorConfiguration.get_show_layout @inventory_item
      @editor_validation = EditorValidation.get_default_validation(@inventory_item)
      @prev_item, @next_item, @prev_page, @next_page, @nav_positions = InventoryItem.near_items_as_ransack(params, @inventory_item)

      @jobs = @inventory_item.delayed_jobs

      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml({ created_at: @item.created_at, updated_at: @item.updated_at, versions: @item.versions }) }
      end
    end
   
    def index
      @results, @hits = InventoryItem.search_as_ransack(params)
      
      @ident_statuses = Source.get_terms("786i_sms")

      index! do |format|
        @inventory_items = @results
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
      
      @inventory_item = InventoryItem.new
      source = Source.find(params[:source_id])
      @inventory_item.source = source
      @parent_object_id = params[:source_id]
      @parent_object_type = "Source" #hardcoded for now
      
      @total_items = source.inventory_items.count
      @inventory_item.source_order = @total_items + 1
      @inventory_item.source = source

      # Apply the right default file
      default_file = "default.marc"
      default_file = "inventory_edition_default.marc" if source.get_record_type == :inventory_edition

      new_marc = MarcInventoryItem.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/inventory_item/#{default_file}")))
      new_marc.load_source false # this will need to be fixed

      # Add the 773 to the parent
      node = MarcNode.new("inventory_item", "773", "", "18")
      node.add_at(MarcNode.new("inventory_item", "w", @inventory_item.source.id, nil), 0)
      new_marc.root.children.insert(new_marc.get_insert_position("773"), node)

      @inventory_item.marc = new_marc

      @editor_profile = EditorConfiguration.get_default_layout @inventory_item
      @editor_validation = EditorValidation.get_default_validation(@inventory_item)
      # Override the default to have a better name
      @page_title = I18n.t('new_inventory_item_page')
      #To transmit correctly @item we need to have @source initialized
      @item = @inventory_item
    end
  
  end
  
  # Include the folder actions
  include FolderControllerActions
  include MarcControllerActions

  ###########
  ## Index ##
  ###########
  
  filter :title_cont, :label => proc{I18n.t(:title_contains)}, :as => :string
  filter :composer_cont, :label => proc{I18n.t(:composer_contains)}, :as => :string

  # _eq is the any field
  filter :title_eq, :label => proc {I18n.t(:any_field_contains)}, :as => :string

  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "InventoryItem").collect {|c| [c.lib_siglum, "folder_id:#{c.id}"]}}
  
  filter :source_id_with_integer, :label => proc {I18n.t(:"record_types.inventory")}, as: :select, 
         collection: proc{Source.where(record_type: MarcSource::RECORD_TYPES[:inventory]).or(Source.where(record_type: MarcSource::RECORD_TYPES[:inventory_edition])).collect {|c| [c.title, "source_id:#{c.id}"]}}

  filter :"786i_with_integer", :label => proc {I18n.t(:"records.identification_status")}, as: :select, 
         collection: proc{@ident_statuses.sort.collect {|k| [k.camelize, "786i:#{k}"]}}

  filter :wf_owner_with_integer, :label => proc {I18n.t(:filter_owner)}, :as => :flexdatalist, data_path: proc{list_for_filter_admin_users_path()}

  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_id), :id    
    column (I18n.t :filter_title), :title
    column (I18n.t :filter_composer), :composer
    column (I18n.t :"record_types.inventory"), :inventory_title, sortable: :inventory_title_order do |element|
      link_to(element.source.title, admin_source_path(element.source.id))
    end

    active_admin_muscat_actions( self, false ) # Hide the "view" button
  end
  
  ##########
  ## Show ##
  ##########
  
  show :title => proc{ active_admin_inventory_item_show_title(@item) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    @item = @arbre_context.assigns[:item]
    if @item.marc_source == nil
      render :partial => "marc_missing"
    else
      render :partial => "marc/show"
    end
    active_admin_user_wf( self, inventory_item )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar :actions, :only => :show do
    render("activeadmin/section_sidebar_show")
  end

  
  ##########
  ## Edit ##
  ##########
  
  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar")
  end

  sidebar :inventory_info do
    #@total_items = controller.view_assigns["total_items"]
    render("inventory_info_sidebar")
  end
  
  form :partial => "editor/edit_wide"

end
