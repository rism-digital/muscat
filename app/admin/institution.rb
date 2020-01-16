ActiveAdmin.register Institution do
  
  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_institutions)}

  # Remove mass-delete action
  batch_action :destroy, false
  include MergeControllerActions
  
  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100]
  
  collection_action :autocomplete_institution_siglum, :method => :get
  collection_action :autocomplete_institution_name, :method => :get

  breadcrumb do
    active_admin_muscat_breadcrumb
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
      @editor_profile = EditorConfiguration.get_default_layout @item
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
      
      @jobs = @institution.delayed_jobs
      
      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml(@item.updated_at, @item.versions) }
      end
    end
   
    def index
      @results, @hits = Institution.search_as_ransack(params)
      index! do |format|
        @institutions = @results
        format.html
      end
    end
    
    def new
      @institution = Institution.new
      
      new_marc = MarcInstitution.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/institution/default.marc"))
      new_marc.load_source false # this will need to be fixed
      @institution.marc = new_marc

      @editor_profile = EditorConfiguration.get_default_layout @institution
      # Since we have only one default template, no need to change the title
      #@page_title = "#{I18n.t('active_admin.new_model', model: active_admin_config.resource_label)} - #{@editor_profile.name}"
      #To transmit correctly @item we need to have @source initialized
      @item = @institution
    end
    
  end
  
  include MarcControllerActions

  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(Institution.find(params[:id]), "referring_sources"))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  filter :"110g_facet_contains", :label => proc{I18n.t(:library_sigla_contains)}, :as => :string
  filter :place_contains, :label => proc {I18n.t(:filter_place)}, :as => :string
  filter :updated_at, :label => proc{I18n.t(:updated_at)}, as: :date_range
  filter :created_at, :label => proc{I18n.t(:created_at)}, as: :date_range

  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "Institution").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  filter :wf_owner_with_integer, :label => proc {I18n.t(:filter_owner)}, as: :select, 
         collection: proc {
           if current_user.has_any_role?(:editor, :admin)
             User.sort_all_by_last_name.map{|u| [u.name, "wf_owner:#{u.id}"]}
           else
             [[current_user.name, "wf_owner:#{current_user.id}"]]
           end
         }
  filter :wf_stage_with_integer, :label => proc {I18n.t(:filter_wf_stage)}, as: :select, 
  collection: proc{[:inprogress, :published, :deleted].collect {|v| [I18n.t("wf_stage." + v.to_s), "wf_stage:#{v}"]}}
 
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_wf_stage) {|institution| status_tag(institution.wf_stage,
      label: I18n.t('status_codes.' + (institution.wf_stage != nil ? institution.wf_stage : ""), locale: :en))}  
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_siglum), :siglum
    column (I18n.t :filter_location_and_name), :name
    column (I18n.t :filter_place), :place
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
  
  show :title => proc{ active_admin_auth_show_title( @item.name, @item.siglum, @item.id) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    render('jobs/jobs_monitor')
    @item = @arbre_context.assigns[:item]
    if @item.marc_source == nil
      render :partial => "marc/missing"
    else
      render :partial => "marc/show"
    end    
    if !resource.get_deposita.empty?
      panel I18n.t :filter_series_items do
        paginated_collection(@item.institutions.page(params[:items_list_page]).per(15), param_name: 'items_list_page', download_links: false) do
          table_for(collection, sortable: true) do
            column :id do |p| link_to p.id, controller: :institutions, action: :show, id: p.id end
            column :siglum
            column :name
            column :place
          end
        end
      end
    end
    active_admin_embedded_source_list( self, institution, !is_selection_mode? )
    
    # Box for people referring to this institution
    active_admin_embedded_link_list(self, institution, Person) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        context.column (I18n.t :filter_full_name), :full_name
        context.column (I18n.t :filter_life_dates), :life_dates
        context.column (I18n.t :filter_alternate_names), :alternate_names
        if !is_selection_mode?
          context.column "" do |person|
            link_to "View", controller: :people, action: :show, id: person.id
          end
        end
      end
    end
    
    # Box for catalogues referring to this institution
    active_admin_embedded_link_list(self, institution, Catalogue) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        context.column (I18n.t :filter_name), :name
        context.column (I18n.t :filter_author), :author
        context.column (I18n.t :filter_description), :description
        if !is_selection_mode?
          context.column "" do |catalogue|
            link_to "View", controller: :catalogues, action: :show, id: catalogue.id
          end
        end
      end
    end 
    
    active_admin_digital_object( self, @item ) if !is_selection_mode?
    active_admin_user_wf( self, institution )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?

  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => institution }
  end

  ##########
  ## Edit ##
  ##########
  
  form :partial => "editor/edit_wide"
  
  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
  end

end
