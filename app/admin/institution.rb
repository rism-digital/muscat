ActiveAdmin.register Institution do

  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_institutions)}

  # Remove mass-delete action
  batch_action :destroy, false
  include MergeControllerActions

  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100, 1000]

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  collection_action :autocomplete_institution_siglum, :method => :get
  collection_action :autocomplete_institution_corporate_name, :method => :get
  collection_action :autocomplete_institution_corporate_name_collate, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do

    autocomplete :institution, [:siglum, :full_name], :display_value => :autocomplete_label_siglum, :extra_data => [:siglum, :full_name], :required => :siglum
    autocomplete :institution, :corporate_name, :display_value => :autocomplete_label_name, :extra_data => [:siglum, :full_name, :place]

    autocomplete :institution, :corporate_name_collate, :extra_data => [:place_order_s], :solr_search => true,
                 :search_field => :corporate_name_autocomplete, :order_field => :total_obj_count_order_is,
                 :display_value => :label_ss, :value_field => :full_name_order_s

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
      @editor_profile = EditorConfiguration.get_default_layout @item
      @editor_validation = EditorValidation.get_default_validation(@item)
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}] #{get_wf_stage_tag(@item.wf_stage)}".html_safe

      if cannot?(:edit, @item)
        redirect_to admin_institution_path(@item), :flash => { :error => I18n.t(:"active_admin.access_denied.message") }
      end

    end

    def show
      begin
        @item = @institution = Institution.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Institution #{params[:id]})" }
        return
      end
      @editor_profile = EditorConfiguration.get_show_layout @institution
      @prev_item, @next_item, @prev_page, @next_page, @nav_positions = Institution.near_items_as_ransack(params, @institution)

      @jobs = @institution.delayed_jobs

      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml({ created_at: @item.created_at, updated_at: @item.updated_at, versions: @item.versions }) }
      end
    end

    def index
      @results, @hits = Institution.search_as_ransack(params)
      @editor_profile = EditorConfiguration.get_default_layout Institution

      @institution_types = Source.get_terms("368a_sms")

      index! do |format|
        @institutions = @results
        format.html
      end
    end

    def new
      @institution = Institution.new

      new_marc = MarcInstitution.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/institution/default.marc")))
      new_marc.load_source false # this will need to be fixed
      @institution.marc = new_marc

      @editor_profile = EditorConfiguration.get_default_layout @institution
      @editor_validation = EditorValidation.get_default_validation(@institution)
      # Since we have only one default template, no need to change the title
      #@page_title = "#{I18n.t('active_admin.new_model', model: active_admin_config.resource_label)} - #{@editor_profile.name}"
      #To transmit correctly @item we need to have @source initialized
      @item = @institution
    end

  end

  # Include the MARC extensions
  include MarcControllerActions

  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(params[:id], Institution, :referring_sources))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end

  ###########
  ## Index ##
  ###########

  # Solr search all fields: "_equal"
  filter :full_name_eq, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  
  filter :has_siglum_with_integer, as: :select, :label => proc{I18n.t(:filter_has_siglum)},
  collection: proc{[["True", "has_siglum:true"], ["False", "has_siglum:false"]]}

  filter :"094a_facet_cont", :label => proc{I18n.t(:library_sigla_contains)}, :as => :string
  filter :place_cont, :label => proc {I18n.t(:filter_place)}, :as => :string
  filter :"667a_cont", :label => proc{I18n.t(:internal_note_contains)}, :as => :string
  filter :updated_at, :label => proc{I18n.t(:updated_at)}, as: :date_range
  filter :created_at, :label => proc{I18n.t(:created_at)}, as: :date_range

  filter :"368a_with_integer", :label => proc{I18n.t(:"records.type_institution")}, as: :select,
  collection: proc{@institution_types.sort.compact.collect {|k| [@editor_profile.get_label(k.to_s), "368a:#{k}"]}}

  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select,
         collection: proc{Folder.where(folder_type: "Institution").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  #filter :wf_owner_with_integer, :label => proc {I18n.t(:filter_owner)}, as: :select,
  #       collection: proc {
  #         if current_user.has_any_role?(:editor, :admin)
  #           User.sort_all_by_last_name.map{|u| [u.name, "wf_owner:#{u.id}"]}
  #         else
  #           [[current_user.name, "wf_owner:#{current_user.id}"]]
  #         end
  #       }
  filter :wf_owner_with_integer, :label => proc {I18n.t(:filter_owner)}, :as => :flexdatalist, data_path: proc{list_for_filter_admin_users_path()}

  filter :wf_stage_with_integer, :label => proc {I18n.t(:filter_wf_stage)}, as: :select,
  collection: proc{[:inprogress, :published, :deleted].collect {|v| [I18n.t("wf_stage." + v.to_s), "wf_stage:#{v}"]}}


  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_wf_stage) {|institution| status_tag(institution.wf_stage,
      label: I18n.t('status_codes.' + (institution.wf_stage != nil ? institution.wf_stage : ""), locale: :en))}
    column (I18n.t :filter_id), :id

    column (I18n.t :filter_siglum), :siglum
    column (I18n.t :filter_location_and_name), :full_name
    column (I18n.t :filter_place), :place
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
  end

  # Include the folder actions
  include FolderControllerActions

  ##########
  ## Show ##
  ##########

  show :title => proc{ active_admin_auth_show_title( @item.full_name, @item.siglum, @item.id, @item.wf_stage).html_safe } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )

    render('jobs/jobs_monitor')

    @item = controller.view_assigns["item"]
    if @item.marc_source == nil
      render :partial => "marc/missing"
    else
      render :partial => "marc/show"
    end

    active_admin_embedded_source_list( self, institution, !is_selection_mode? )

    # This one cannot use the compact form
    active_admin_embedded_link_list(self, institution, Holding) do |context|
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

    active_adnin_create_list_for(self, Institution, institution, siglum: I18n.t(:filter_siglum), full_name: I18n.t(:filter_full_name), place: I18n.t(:filter_place))
    active_adnin_create_list_for(self, InventoryItem, institution, composer: I18n.t(:filter_composer), title: I18n.t(:filter_title))
    active_adnin_create_list_for(self, Person, institution, full_name: I18n.t(:filter_full_name), life_dates: I18n.t(:filter_life_dates), alternate_names: I18n.t(:filter_alternate_names))
    active_adnin_create_list_for(self, Publication, institution, short_name: I18n.t(:filter_title_short), author: I18n.t(:filter_author), title: I18n.t(:filter_title))    
    active_adnin_create_list_for(self, Work, institution, title: I18n.t(:filter_title))

    active_admin_digital_object( self, @item ) if !is_selection_mode?
    active_admin_user_wf( self, institution )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end

  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => institution }
  end

  sidebar :folders, :only => :show do
    render :partial => "activeadmin/section_sidebar_folder_actions", :locals => { :item => institution }
  end

  ##########
  ## Edit ##
  ##########

  form :partial => "editor/edit_wide"

  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
  end

end
