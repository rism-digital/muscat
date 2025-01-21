ActiveAdmin.register Publication do
  
  include MergeControllerActions
  
  collection_action :autocomplete_publication_short_name, :method => :get
  collection_action :autocomplete_publication_only_short_name, :method => :get

  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_publications)}

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
    autocomplete :publication, [:short_name, :author, :title], :display_value => :autocomplete_label , :extra_data => [:author, :date, :title]

    autocomplete :publication, :only_short_name, :record_field => :short_name, :string_boundary => true, :display_value => :label, :getter_function => :get_autocomplete_title_with_count

    def get_autocomplete_title_with_count(token,  options = {})

      #sanit = ActiveRecord::Base.send(:sanitize_sql_like, token)

      term_escaped = Regexp.escape(token)
      search_term = "\\b#{term_escaped}.*\\b"

      query = "SELECT `publications`.`id`, `publications`.`short_name`, `publications`.`author`, `publications`.`date`, `publications`.`title`,
      COUNT(publications.id) as count \
      FROM `publications` \
      JOIN sources_to_publications AS stp on publications.id = stp.publication_id \
      WHERE (publications.short_name REGEXP (?) \
      or publications.author REGEXP (?) \
      or publications.title REGEXP (?) ) \
      and (publications.short_name != '') \
      GROUP BY publications.id \
      ORDER BY COUNT(publications.id) DESC LIMIT 20"
      
      return Publication.find_by_sql([query, search_term, search_term, search_term])
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
      begin
        @item = @publication = Publication.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_publications_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Publication #{params[:id]})" }
        return
      end

      @editor_profile = EditorConfiguration.get_show_layout @publication
      @prev_item, @next_item, @prev_page, @next_page, @nav_positions = Publication.near_items_as_ransack(params, @publication)
      
      @jobs = @publication.delayed_jobs
      
      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml({ created_at: @item.created_at, updated_at: @item.updated_at, versions: @item.versions }) }
      end
    end

    def edit
      flash.now[:error] = params[:validation_error] if params[:validation_error]
      @item = Publication.find(params[:id])
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_default_layout @item
      @editor_validation = EditorValidation.get_default_validation(@item)
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"

      if cannot?(:edit, @item)
        redirect_to admin_publication_path(@item), :flash => { :error => I18n.t(:"active_admin.access_denied.message") }
      end

    end

    def index
      @results, @hits = Publication.search_as_ransack(params)
      @categories = Publication.get_terms("240g_sm")

      @editor_profile = EditorConfiguration.get_default_layout Publication

      index! do |format|
        @publications = @results
        format.html
      end
    end

    def new
      flash.now[:error] = I18n.t(params[:validation_error], term: params[:validation_term]) if params[:validation_error]
      @publication = Publication.new
      if params[:existing_title] and !params[:existing_title].empty?
        # Check that the record does exist...
        begin
          base_item = Publication.find(params[:existing_title])
        rescue ActiveRecord::RecordNotFound
          redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Publication #{params[:id]})" }
          return
        end
        
        new_marc = MarcPublication.new(base_item.marc.marc_source)
        new_marc.reset_to_new
        new_marc.insert_duplicated_from("981", base_item.id.to_s)
        @publication.marc = new_marc
      else
        new_marc = MarcPublication.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/publication/default.marc")))
        new_marc.load_source false # this will need to be fixed
        @publication.marc = new_marc
      end
      @editor_profile = EditorConfiguration.get_default_layout @publication
      @editor_validation = EditorValidation.get_default_validation(@publication)
      @item = @publication
    end

  end
    
  # Include the MARC extensions
  include MarcControllerActions
  
  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(params[:id], Publication, :referring_sources))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end
  
  member_action :duplicate, method: :get do
    redirect_to action: :new, :existing_title => params[:id]
    return
  end
 
  collection_action :work_catalogs  do
    #doc_url = 'https://docs.google.com/spreadsheets/d/1Wh45W93lUZfcf2AOb2OLn9LcIvbY7b55QgmoJ87xAc0/export?exportFormat=csv'

    csv_string = URI.open(WORK_CATALOG_DOC).read rescue nil
    @csv_data = CSV.parse(csv_string, headers: true).map(&:to_hash) if csv_string

    #ap @csv_data

    @paginated = Kaminari.paginate_array(@csv_data)

    @page_title = "Work Catalogs"
  end

  sidebar :custom, only: :work_catalogs do
    "Sidebar contents"
  end

  ###########
  ## Index ##
  ###########  
  
  # Solr search all fields: "_equal"
  filter :short_name_eq, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  filter :"100a_or_700a_cont", :label => proc {I18n.t(:filter_author_or_editor)}, :as => :string
  filter :title_cont, :label => proc {I18n.t(:filter_description)}, :as => :string
  
  #filter :"240g_contains", :label => proc {I18n.t(:filter_category_type)}, :as => :select,
  #  collection: proc{["Bibliography", "Catalog", "Collective catalogue", "Encyclopedia", "Music edition", "Other",
  #    "Thematic catalog", "Work catalog"] }

  filter :"240g_with_integer", :label => proc{I18n.t(:"filter_category_type")}, as: :select,
    collection: proc{@categories.sort.collect {|k| [@editor_profile.get_label(k.to_s), "240g:#{k}"]}}

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

  # work catalogue filter
  filter :work_catalogue_with_integer, :label => proc{I18n.t(:work_catalogue)}, as: :select, 
  collection: [["Yes", "work_catalogue:true"],["No", "work_catalogue:false"]], :if => proc{ current_user.has_any_role?(:admin) }

  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_wf_stage) {|cat| status_tag(cat.wf_stage,
      label: I18n.t('status_codes.' + (cat.wf_stage != nil ? cat.wf_stage : ""), locale: :en))}  
    column (I18n.t :filter_id), :id    
    column (I18n.t :filter_title_short), :short_name
    column (I18n.t :filter_title), :title
    column (I18n.t :filter_author), :author
    column (I18n.t :work_catalogue), :work_catalogue if current_user.has_any_role?(:admin)
    column (I18n.t :filter_sources), :src_count_order, sortable: :src_count_order do |element|
			all_hits = @arbre_context.assigns[:hits]
			active_admin_stored_from_hits(all_hits, element, :src_count_order)
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
  
  show :title => proc{ active_admin_publication_show_title( @item.author, @item.title&.truncate(60), @item.id) } do
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
    active_admin_embedded_source_list(self, publication, !is_selection_mode? )

    # Box for people referring to this publication
    active_admin_embedded_link_list(self, publication, Person) do |context|
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
    
    # Box for institutions referring to this publication
    active_admin_embedded_link_list(self, publication, Institution) do |context|
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
    
    active_admin_embedded_link_list(self, publication, Work) do |context|
      context.table_for(context.collection) do |cr|
        column (I18n.t :filter_id), :id  
        column (I18n.t :filter_title), :title
        column "Opus", :opus
        column "Catalogue", :catalogue
        if !is_selection_mode?
          context.column "" do |work|
            link_to "View", controller: :works, action: :show, id: work.id
          end
        end
      end
    end

    active_admin_embedded_link_list(self, publication, Publication) do |context|
      context.table_for(context.collection) do |cr|
        column (I18n.t :filter_id), :id  
        column (I18n.t :filter_title), :title
        column "Author", :author
        column "Date", :date
        if !is_selection_mode?
          context.column "" do |publication|
            link_to "View", controller: :publications, action: :show, id: publication.id
          end
        end
      end
    end

    active_admin_user_wf( self, publication )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => publication }
  end

  sidebar :statistics, :only => :show do
    render :partial => "publications/work_statistics"
  end

  sidebar :folders, :only => :show do
    render :partial => "activeadmin/section_sidebar_folder_actions", :locals => { :item => publication }
  end

  ##########
  ## Edit ##
  ##########
  
  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
  end
  
  form :partial => "editor/edit_wide"
  
end
