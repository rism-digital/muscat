ActiveAdmin.register Catalogue do
  
  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_catalogues)}

  # Remove mass-delete action
  batch_action :destroy, false
  
  # Remove all action items
  config.clear_action_items!

  collection_action :autocomplete_catalogue_name, :method => :get

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :catalogue, [:name, :author, :description], :display_value => :autocomplete_label , :extra_data => [:author, :date, :description]
    
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
      @item = Catalogue.find(params[:id])
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_default_layout @item
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"
    end

    def show
      begin
        @item = @catalogue = Catalogue.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Catalogue #{params[:id]})" }
        return
      end
      @editor_profile = EditorConfiguration.get_show_layout @catalogue
      @prev_item, @next_item, @prev_page, @next_page = Catalogue.near_items_as_ransack(params, @catalogue)
      
      @jobs = @catalogue.delayed_jobs
      
      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml(@item.updated_at, @item.versions) }
      end
    end
    
    def index
      @results, @hits = Catalogue.search_as_ransack(params)
      
      index! do |format|
        @catalogues = @results
        format.html
      end
    end
    
    def new
      @catalogue = Catalogue.new
      
      new_marc = MarcCatalogue.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/catalogue/default.marc"))
      new_marc.load_source false # this will need to be fixed
      @catalogue.marc = new_marc

      @editor_profile = EditorConfiguration.get_default_layout @catalogue
      # Since we have only one default template, no need to change the title
      #@page_title = "#{I18n.t('active_admin.new_model', model: active_admin_config.resource_label)} - #{@editor_profile.name}"
      #To transmit correctly @item we need to have @source initialized
      @item = @catalogue
    end
    
  end
  
  include MarcControllerActions
  
  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(Catalogue.find(params[:id]), "referring_sources"))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end

  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  filter :"100a_or_700a_contains", :label => proc {I18n.t(:filter_author_or_editor)}, :as => :string
  filter :description_contains, :label => proc {I18n.t(:filter_description)}, :as => :string
  filter :"240g_contains", :label => proc {I18n.t(:filter_record_type)}, :as => :string
  filter :"260b_contains", :label => proc {I18n.t(:filter_publisher)}, :as => :string
  filter :"place_contains", :label => proc {I18n.t(:filter_place)}, :as => :string
  filter :"date_contains", :label => proc {I18n.t(:filter_date)}, :as => :string
  filter :updated_at, :label => proc{I18n.t(:updated_at)}, as: :date_range
  filter :created_at, :label => proc{I18n.t(:created_at)}, as: :date_range

  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "Catalogue").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_wf_stage) {|catalogue| status_tag(catalogue.wf_stage,
      label: I18n.t('status_codes.' + (catalogue.wf_stage != nil ? catalogue.wf_stage : ""), locale: :en))}  
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_name), :name do |catalogue| 
      catalogue.name.truncate(30) if catalogue.name
    end
    column (I18n.t :filter_description), :description do |catalogue| 
      catalogue.description.truncate(60) if catalogue.description
    end
    column (I18n.t :filter_author), :author
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
  
  show :title => proc{ active_admin_catalogue_show_title( @item.author, @item.description.truncate(60), @item.id) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    render('jobs/jobs_monitor')
    @item = @arbre_context.assigns[:item]
    if @item.marc_source == nil
      render :partial => "marc_missing"
    else
      render :partial => "marc/show"
    end
    active_admin_embedded_source_list( self, catalogue, params[:qe], params[:src_list_page], !is_selection_mode? )

    if resource.revue_title.empty? && !resource.get_items.empty?
      panel I18n.t :filter_series_items do
        search=Catalogue.solr_search do 
          fulltext(params[:id], :fields=>['7600'])
          paginate :page => params[:items_list_page], :per_page=>15
          order_by(:date_order)
        end
        paginated_collection(search.results, param_name: 'items_list_page', download_links: false) do
          table_for(collection, sortable: true) do
            column :id do |p| link_to p.id, controller: :catalogues, action: :show, id: p.id end
            column :author
            column :description
            column :date
          end
        end
      end
    end

    active_admin_user_wf( self, catalogue )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => catalogue }
  end

  ##########
  ## Edit ##
  ##########
  
  form :partial => "editor/edit_wide"
  
  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
  end
  
end
