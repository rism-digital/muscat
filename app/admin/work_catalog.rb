ActiveAdmin.register Publication, as: "WorkCatalog" do
  menu :parent => "indexes_menu", :label => proc {I18n.t(:work_catalog)}, :if => proc{ can?(:edit, Work) }

  # Remove mass-delete action
  batch_action :destroy, false
  
  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100, 1000]

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

    def check_model_errors(object)
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end
    
    def action_methods
      return super - ['new', 'edit', 'destroy'] if is_selection_mode?
      super
    end
    
    def permitted_params
      params.permit!
    end
    
    def show
    end

    def edit
    end

    def index

      # We need to only show the work catalogs
      params[:q] ||= {}
      #params[:q]["240g_with_integer"] = "240g:Catalog of works"
      params[:q]["wc_catalog_with_integer"] = "wc_catalog:true"

      @results, @hits = Publication.search_as_ransack(params)
      @categories = Publication.get_terms("240g_sm")

      @editor_profile = EditorConfiguration.get_default_layout Publication

      index! do |format|
        @work_catalogs = @results
        format.html
      end
    end

    def new
    end

  end
  
  ###########
  ## Index ##
  ###########  
  
  filter :short_name_eq, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  filter :"100a_or_700a_cont", :label => proc {I18n.t(:filter_author_or_editor)}, :as => :string
  filter :title_cont, :label => proc {I18n.t(:filter_description)}, :as => :string
  
  filter :"260b_cont", :label => proc {I18n.t(:filter_publisher)}, :as => :string
  filter :"place_cont", :label => proc {I18n.t(:filter_place_of_publication)}, :as => :string
  filter :"date_cont", :label => proc {I18n.t(:filter_date_of_publication)}, :as => :string
  filter :updated_at, :label => proc{I18n.t(:updated_at)}, as: :date_range
  filter :created_at, :label => proc{I18n.t(:created_at)}, as: :date_range
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "Publication").collect {|c| [c.name, "folder_id:#{c.id}"]}}

  filter :wf_owner_with_integer, :label => proc {I18n.t(:filter_owner)}, :as => :flexdatalist, data_path: proc{list_for_filter_admin_users_path()}

  filter :work_catalogue_with_integer, :label => proc{I18n.t(:work_catalog)}, as: :select, 
  collection: proc{Publication.work_catalogues.collect {|k,v| [I18n.t("work_catalogue_labels." + k), "work_catalogue:#{k}"]}}, :if => proc{ can?(:edit, Work) }
  

  index title: I18n.t(:work_catalog), :download_links => false do
    selectable_column if !is_selection_mode?
    column((I18n.t :filter_wf_stage), sortable: :wf_stage) {|i| active_admin_wf_stage_column(self, i)} 
    column "ID", :id, sortable: :id do |c|
      link_to c.id, admin_publication_path(c.id)
    end

    column (I18n.t :filter_title_short), :short_name

    column (I18n.t :filter_composer), :wc_composer_name_order, sortable: :wc_composer_name_order do |element|
			name = active_admin_stored_from_hits(controller.view_assigns["hits"], element, :wc_composer_name_order)
      id = active_admin_stored_from_hits(controller.view_assigns["hits"], element, :wc_composer_id_order)

      if !id.blank?
        link_to name, admin_person_path(id)
      else
        status_tag(:deleted, label: "no att in 700")
      end
		end

    column (I18n.t :filter_date), :wc_composer_dates_order, sortable: :wc_composer_dates_order do |element|
			active_admin_stored_from_hits(controller.view_assigns["hits"], element, :wc_composer_dates_order)
		end

    column "CAT", :work_catalogue, sortable: :work_catalogue_order do  |cat|
      status_tag(cat.work_catalogue, label: I18n.t('work_catalogue_tags.' + (cat.work_catalogue != nil ? cat.work_catalogue : ""), locale: :en))
    end

    column "INCIP", :wc_has_incipits_order, sortable: :wc_has_incipits_order do |element|
			gnd = active_admin_stored_from_hits(controller.view_assigns["hits"], element, :wc_has_incipits_order)
      status_tag(gnd)
		end

    column "GND", :wc_gnd_links_order, sortable: :wc_gnd_links_order do |element|
			gnd = active_admin_stored_from_hits(controller.view_assigns["hits"], element, :wc_gnd_links_order)
      status_tag(gnd)
		end

    column (I18n.t :menu_works), :wc_works_count_order, sortable: :wc_works_count_order do |element|
			active_admin_stored_from_hits(controller.view_assigns["hits"], element, :wc_works_count_order)
		end

    column (I18n.t :menu_sources), :wc_sources_count_order, sortable: :wc_sources_count_order do |element|
			active_admin_stored_from_hits(controller.view_assigns["hits"], element, :wc_sources_count_order)
		end

    column "URL", :wc_catalog_url_order, sortable: :wc_catalog_url_order do |element|
			url = active_admin_stored_from_hits(controller.view_assigns["hits"], element, :wc_catalog_url_order)
      status_tag(url.blank? ? :no : :yes)
		end

    column (I18n.t :filter_notes), :wc_notes_order, sortable: :wc_notes_order do |element|
			active_admin_stored_from_hits(controller.view_assigns["hits"], element, :wc_notes_order)
		end

    
    #column (I18n.t :filter_author), :author
    #column (I18n.t :filter_title), :title
    #column (I18n.t :filter_date), :date
    
    #active_admin_muscat_actions( self )
  end
  
end
