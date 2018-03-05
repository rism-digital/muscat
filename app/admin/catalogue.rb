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
      flash.now[:error] = I18n.t(params[:validation_error], term: params[:validation_term]) if params[:validation_error]
      @item = Catalogue.find(params[:id])
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_default_layout @item
      @editor_validation = EditorValidation.get_default_validation(@item)
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"
    end

    def show
      begin
        @item = @catalogue = Catalogue.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_catalogues_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Catalogue #{params[:id]})" }
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
      flash.now[:error] = I18n.t(params[:validation_error], term: params[:validation_term]) if params[:validation_error]
      @catalogue = Catalogue.new
      if params[:existing_title] and !params[:existing_title].empty?
        begin
          base_item = Catalogue.find(params[:existing_title])
        rescue ActiveRecord::RecordNotFound
          redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Catalogue #{params[:id]})" }
          return
        end
        
        new_marc = MarcCatalogue.new(base_item.marc.marc_source)
        new_marc.reset_to_new
        @catalogue.marc = new_marc
      else
        new_marc = MarcCatalogue.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/catalogue/default.marc"))
        new_marc.load_source false # this will need to be fixed
        @catalogue.marc = new_marc
      end
      @editor_profile = EditorConfiguration.get_default_layout @catalogue
      @editor_validation = EditorValidation.get_default_validation(@catalogue)
      @item = @catalogue
    end
  end
  
  include MarcControllerActions
  
  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(Catalogue.find(params[:id]), "referring_sources"))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end
  
  member_action :duplicate, method: :get do
    redirect_to action: :new, :existing_title => params[:id]
    return
  end
 

  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  filter :"100a_or_700a_contains", :label => proc {I18n.t(:filter_author_or_editor)}, :as => :string
  filter :description_contains, :label => proc {I18n.t(:filter_description)}, :as => :string
  filter :"240g_contains", :label => proc {I18n.t(:filter_category_type)}, :as => :select,
    collection: proc{["Bibliography", "Catalog", "Collective catalogue", "Encyclopedia", "Music edition", "Other",
      "Thematic catalog", "Work catalog"] }
  filter :"260b_contains", :label => proc {I18n.t(:filter_publisher)}, :as => :string
  filter :"place_contains", :label => proc {I18n.t(:filter_place_of_publication)}, :as => :string
  filter :"date_contains", :label => proc {I18n.t(:filter_date_of_publication)}, :as => :string
  filter :updated_at, :label => proc{I18n.t(:updated_at)}, as: :date_range
  filter :created_at, :label => proc{I18n.t(:created_at)}, as: :date_range

  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "Catalogue").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  
  index :download_links => false do
    selectable_column if !is_selection_mode?

    column (I18n.t :filter_id), :id    
    column (I18n.t :filter_title_short), :name
    column (I18n.t :filter_title), :description do |catalogue| 
      catalogue.description.truncate(64, separator: ' ') if catalogue.description

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
    
    ## Source box. Use the standard helper so it is the same everywhere
    active_admin_embedded_source_list(self, catalogue, !is_selection_mode? )

    # Box for people referring to this catalogue
    active_admin_embedded_link_list(self, catalogue, Person) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        context.column (I18n.t :filter_full_name), :full_name
        context.column (I18n.t :filter_life_dates), :life_dates
        context.column (I18n.t :filter_birth_place), :birth_place
        context.column (I18n.t :filter_alternate_names), :alternate_names
        if !is_selection_mode?
          context.column "" do |person|
            link_to "View", controller: :people, action: :show, id: person.id
          end
        end
      end
    end
    
    # Box for institutions referring to this catalogue
    active_admin_embedded_link_list(self, catalogue, Institution) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        context.column (I18n.t :filter_siglum), :siglum
        context.column (I18n.t :filter_name), :name
        context.column (I18n.t :filter_place), :place
        if !is_selection_mode?
          context.column "" do |ins|
            link_to "View", controller: :institutions, action: :show, id: ins.id
          end
        end
      end
    end
    
    if !resource.get_items.empty?
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
