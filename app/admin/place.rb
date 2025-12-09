include Triggers

ActiveAdmin.register Place do
  # Temporary hide menu item because place model has to be configured first
  # menu false
  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_places)}

  # Remove mass-delete action
  batch_action :destroy, false

  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100, 1000]

  collection_action :autocomplete_place_name, :method => :get

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do

    autocomplete :place, :name, :display_value => :autocomplete_label, :extra_data => [:country, :district]

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
      @item = Place.find(params[:id])
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_default_layout @item
      @editor_validation = EditorValidation.get_default_validation(@item)
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"

      if cannot?(:edit, @item)
        redirect_to admin_place_path(@item), :flash => { :error => I18n.t(:"active_admin.access_denied.message") }
      end
    end

    def show
      begin
        @item = @place = Place.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Place #{params[:id]})" }
        return
      end
      @editor_profile = EditorConfiguration.get_show_layout @place
      @editor_validation = EditorValidation.get_default_validation(@place)
      @prev_item, @next_item, @prev_page, @next_page, @nav_positions = Place.near_items_as_ransack(params, @place)

      @jobs = @place.delayed_jobs

      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml({ created_at: @item.created_at, updated_at: @item.updated_at, versions: @item.versions }) }
      end
    end

    def index
      @results, @hits = Place.search_as_ransack(params)
      index! do |format|
        @places = @results
        format.html
      end
    end

    def new
      @place = Place.new
      converted = false

      if params.include?(:tgn_id)
        tgn_id = params.fetch(:tgn_id).gsub("tgn:", "")
        rec = TgnClient::pull_from_tgn(tgn_id)
        converted = TgnConverter::to_place_marc(rec)
      end

      marc_file = converted || File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/place/default.marc"))
      
      new_marc = MarcPlace.new(marc_file)
      new_marc.load_source false # this will need to be fixed
      @place.marc = new_marc

      @editor_profile = EditorConfiguration.get_default_layout @place
      # Since we have only one default template, no need to change the title
      #@page_title = "#{I18n.t('active_admin.new_model', model: active_admin_config.resource_label)} - #{@editor_profile.name}"
      #To transmit correctly @item we need to have @source initialized
      @item = @place
    end

  end

  # Include the MARC extensions
  include MarcControllerActions

  collection_action :tgn_search, method: :get do
    begin
      params.require(:q)
      begin
        @results = TgnClient::search(params[:q])
      rescue Faraday::ConnectionFailed
        ## inform user here
      end
      
    rescue ActionController::ParameterMissing
      @results = nil
    end

    # Map these to Muscat-ids if possible
    @results.each do |r|
      sanit_id = r[:subject].gsub("tgn:", "")
      begin
        ids = Place.where(tgn_id: sanit_id)
        r[:in_muscat] = ids.count > 0 ? true : false
      rescue ActiveRecord::RecordNotFound
        r[:in_muscat] = false
      end
    end

    render 'tgn_results', layout: "active_admin", locals: { results: @results }
  end

  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(params[:id], Place, :referring_sources))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end

  ###########
  ## Index ##
  ###########

  # Solr search all fields: "_equal"
  filter :name_eq, :label => proc {I18n.t(:any_field_contains)}, :as => :string

  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
    collection: proc{Folder.where(folder_type: "Place").collect {|c| [c.name, "folder_id:#{c.id}"]}}

  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_name), :name
    #column (I18n.t :filter_district), :district
    #column (I18n.t :filter_country), :country
    column (I18n.t :tgn_id), :tgn_id
    column (I18n.t :hierarchy), :hierarchy
    column (I18n.t :filter_sources), :src_count_order, sortable: :src_count_order do |element|
			active_admin_stored_from_hits(controller.view_assigns["hits"], element, :src_count_order)
		end
    column (I18n.t :filter_authorities), :referring_objects_order, sortable: :referring_objects_order do |element|
			active_admin_stored_from_hits(controller.view_assigns["hits"], element, :referring_objects_order)
		end

    active_admin_muscat_actions( self )
  end

  sidebar :actions, :only => :index do
    render :partial => "activeadmin/section_sidebar_index"
    render partial: "tgn_search_actions"
  end

  # Include the folder actions
  include FolderControllerActions

  ##########
  ## Show ##
  ##########

  show do
    active_admin_navigation_bar( self )

    render('jobs/jobs_monitor')

    @item = controller.view_assigns["item"]
    if @item.marc_source == nil
      render :partial => "marc/missing"
    else
      render :partial => "marc/show"
    end

    active_admin_embedded_source_list( self, place, !is_selection_mode? )
    
    # This one cannot use the compact form
    active_admin_embedded_link_list(self, place, Holding) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        context.column (I18n.t :filter_siglum), :lib_siglum
        context.column (I18n.t :filter_source_name) {|hld| hld.source.std_title}
        context.column (I18n.t :filter_source_composer) {|hld| hld.source.composer}
        if !is_selection_mode?
          context.column "" do |hold|
            link_to I18n.t(:view_source), controller: :sources, action: :show, id: hold.source.id
          end
        end
      end
    end
    
    active_adnin_create_list_for(self, Institution, place, siglum: I18n.t(:filter_siglum), full_name: I18n.t(:filter_full_name), place: I18n.t(:filter_place))
    active_adnin_create_list_for(self, Person, place, full_name: I18n.t(:filter_full_name), life_dates: I18n.t(:filter_life_dates), alternate_names: I18n.t(:filter_alternate_names))
    active_adnin_create_list_for(self, Publication, place, short_name: I18n.t(:filter_title_short), author: I18n.t(:filter_author), title: I18n.t(:filter_title))    
    active_adnin_create_list_for(self, Work, place, title: I18n.t(:filter_title))

    active_admin_user_wf( self, place )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end

  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => place }
  end

  sidebar :folders, :only => :show do
    render :partial => "activeadmin/section_sidebar_folder_actions", :locals => { :item => place }
  end

  ##########
  ## Edit ##
  ##########

  form :partial => "editor/edit_wide"

  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
  end

  #sidebar :actions, :only => [:edit, :new, :update] do
  #  render :partial => "activeadmin/section_sidebar_edit", :locals => { :item => place }
  #end

end
