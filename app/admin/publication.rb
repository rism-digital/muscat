ActiveAdmin.register Publication do

  include MergeControllerActions

  collection_action :autocomplete_publication_name, :method => :get

  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_publications)}

  # Remove mass-delete action
  batch_action :destroy, false

  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100]

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
    autocomplete :publication, [:name, :author, :description], :display_value => :autocomplete_label , :extra_data => [:author, :date, :description]


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

      # Try to load the MARC object.
      begin
        @item.marc.load_source true
      rescue ActiveRecord::RecordNotFound
        # If resolving the remote objects fails, it means
        # Something went wrong saving the source, like a DB falure
        # continue to show the page so the user does not panic, and
        # show an error message. Also send a mail to the administrators
        flash[:error] = I18n.t(:unloadable_record)
        AdminNotifications.notify("Publication #{@item.id} seems unloadable, please check", @item).deliver_now
      end
      
      @editor_profile = EditorConfiguration.get_show_layout @item
      @prev_item, @next_item, @prev_page, @next_page = Publication.near_items_as_ransack(params, @item)

      @jobs = @publication.delayed_jobs

      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml(@item.updated_at, @item.versions) }
      end
    end

    def edit
      flash.now[:error] = params[:validation_error] if params[:validation_error]
      @item = Publication.find(params[:id])
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_default_layout @item
      @editor_validation = EditorValidation.get_default_validation(@item)
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"
    end

    def index
      @results, @hits = Publication.search_as_ransack(params)

      index! do |format|
        @publications = @results
        format.html
      end
    end

    def new
      @publication = Publication.new
      @template_name = ""

      if (!params[:existing_title] || params[:existing_title].empty?) && (!params[:new_record_type] || params[:new_record_type].empty?)
        redirect_to action: :select_new_template
        return
      end

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

  collection_action :select_new_template, :method => :get do
    @page_title = "#{I18n.t(:select_template)}"
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
         collection: proc{Folder.where(folder_type: "Publication").collect {|c| [c.name, "folder_id:#{c.id}"]}}

  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_wf_stage) {|cat| status_tag(cat.wf_stage,
      label: I18n.t('status_codes.' + (cat.wf_stage != nil ? cat.wf_stage : ""), locale: :en))}
    column (I18n.t :filter_id), :id
    column (I18n.t :filter_title_short), :name
    column (I18n.t :filter_title), :description
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

  show :title => proc{ active_admin_publication_show_title( @item.author, @item.description.truncate(60), @item.id) } do
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

    if !resource.get_items.empty?
      panel I18n.t :filter_series_items do
        search=Publication.solr_search do
          fulltext(params[:id], :fields=>['7600'])
          paginate :page => params[:items_list_page], :per_page=>15
          order_by(:date_order)
        end
        paginated_collection(search.results, param_name: 'items_list_page', download_links: false) do
          table_for(collection, sortable: true) do
            column :id do |p| link_to p.id, controller: :publications, action: :show, id: p.id end
            column :author
            column :description
            column :date
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

  ##########
  ## Edit ##
  ##########

  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
  end

  sidebar :help, :only => [:select_new_template] do
    render :partial => "template_help"
  end

  form :partial => "editor/edit_wide"

end
