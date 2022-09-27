ActiveAdmin.register Person do

  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_people)}

  # Remove mass-delete action
  batch_action :destroy, false
  include MergeControllerActions

  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100]

  # Not everybody likes cleverly ordered things
  if defined?(RISM::CLEVER_ORDERING) && RISM::CLEVER_ORDERING == true
    config.sort_order = 'full_name_ans_asc'
  else
    config.sort_order = 'full_name_asc'
  end

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  collection_action :autocomplete_person_full_name, :method => :get
  collection_action :autocomplete_person_550a_sms, :method => :get

  collection_action :viaf, method: :get do
    respond_to do |format|
        format.json { render json: Person.get_viaf(params[:viaf_input])  }
    end
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do

    autocomplete :person, :full_name, :display_value => :autocomplete_label , :extra_data => [:life_dates]
    autocomplete :person, "550a_sms", :solr => true

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
      @item = Person.find(params[:id])
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_default_layout @item
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"

      if cannot?(:edit, @item)
        redirect_to admin_person_path(@item), :flash => { :error => I18n.t(:"active_admin.access_denied.message") }
      end

      if current_user.restricted?("person") 
        if @item.wf_owner==current_user.id
          @restricted=""
        else
          @restricted="disabled"
        end
      end
    end

    def show
      begin
        @item = @person = Person.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Person #{params[:id]})" }
        return
      end
      @editor_profile = EditorConfiguration.get_show_layout @person
      @prev_item, @next_item, @prev_page, @next_page = Person.near_items_as_ransack(params, @person)

      @jobs = @person.delayed_jobs

      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml(@item.updated_at, @item.versions) }
      end
    end

    def index
      person = Person.new
      new_marc = MarcPerson.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/person/default.marc")))
      new_marc.load_source false # this will need to be fixed
      person.marc = new_marc
      @editor_profile = EditorConfiguration.get_default_layout person

      # Get the terms for 550a, the "profession filter"
      @profession_types = Source.get_terms("550a_sms")

      @results, @hits = Person.search_as_ransack(params)
      index! do |format|
        @people = @results
        format.html
      end
    end

    def new
      @person = Person.new

      new_marc = MarcPerson.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/person/default.marc")))
      new_marc.load_source false # this will need to be fixed
      @person.marc = new_marc

      @editor_profile = EditorConfiguration.get_default_layout @person
      # Since we have only one default template, no need to change the title
      #@page_title = "#{I18n.t('active_admin.new_model', model: active_admin_config.resource_label)} - #{@editor_profile.name}"
      #To transmit correctly @item we need to have @source initialized
      @item = @person
    end

  end

  # Include the MARC extensions
  include MarcControllerActions

  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(params[:id], Person, :referring_sources))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end

  member_action :resave, method: :get do
    job = Delayed::Job.enqueue(SaveItemsJob.new(params[:id], Person, :referring_sources))
    redirect_to resource_path(params[:id]), notice: "Save Job started #{job.id}"
  end

  ###########
  ## Index ##
  ###########

  # temporary, to be replaced by Solr
  #filter :id_eq, :label => proc {I18n.t(:filter_id)}
  #filter :full_name_contains, :label => proc {I18n.t(:filter_full_name)}, :as => :string
	filter :full_name_or_400a_contains, :label => proc {I18n.t(:filter_full_name)}, :as => :string
  filter :"100d_contains", :label => proc {I18n.t(:filter_person_100d)}, :as => :string
  filter :"375a_contains", :label => proc {I18n.t(:filter_person_375a)}, :as => :select,
  # FIXME locale not read
    :collection => [[I18n.t(:filter_male), 'male'], [ I18n.t(:filter_female), 'female'], [I18n.t(:filter_unknown), 'unknown']]
  #filter :"550a_contains", :label => proc {I18n.t(:filter_person_550a)}, :as => :string

  filter :"550a_with_integer", :label => proc{I18n.t(:filter_person_550a)}, as: :select,
  collection: proc{@profession_types.sort.collect {|k| [k.camelize, "550a:#{k}"]}}

  filter :"043c_contains", :label => proc {I18n.t(:filter_person_043c)}, as: :select,
    collection: proc {
      @editor_profile.options_config["043"]["tag_params"]["codes"].map{|e| [@editor_profile.get_label(e), e]}.sort_by{|k,v| k}
    }
  filter :"551a_contains", :label => proc {I18n.t(:filter_person_551a)}, :as => :string
  filter :"100d_birthdate_contains", :label => proc {I18n.t(:filter_person_100d_birthdate)}, :as => :string
  filter :"100d_deathdate_contains", :label => proc {I18n.t(:filter_person_100d_deathdate)}, :as => :string
  filter :"667a_contains", :label => proc{I18n.t(:internal_note_contains)}, :as => :string
  filter :full_name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  filter :updated_at, :label => proc {I18n.t(:updated_at)}, :as => :date_range
  filter :created_at, :label => proc{I18n.t(:created_at)}, as: :date_range

  filter :wf_owner_with_integer, :label => proc {I18n.t(:filter_owner)}, as: :select,
         collection: proc {
           if current_user.has_any_role?(:editor, :admin)
             User.all.collect {|c| [c.name, "wf_owner:#{c.id}"]}
           else
             [[current_user.name, "wf_owner:#{current_user.id}"]]
           end
         }

  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select,
         collection: proc{Folder.where(folder_type: "Person").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  filter :wf_stage_with_integer, :label => proc {I18n.t(:filter_wf_stage)}, as: :select,
    collection: proc{[:inprogress, :published, :deleted].collect {|v| [I18n.t("wf_stage." + v.to_s), "wf_stage:#{v}"]}}


  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_wf_stage) {|person| status_tag(person.wf_stage,
      label: I18n.t('status_codes.' + (person.wf_stage != nil ? person.wf_stage : ""), locale: :en))}
    column (I18n.t :filter_id), :id

    if defined?(RISM::CLEVER_ORDERING) && RISM::CLEVER_ORDERING == true
      column (I18n.t :filter_full_name), :full_name_ans, sortable: :full_name_ans do |element|
        element.full_name
      end
    else
      column (I18n.t :filter_full_name), :full_name
    end

    column (I18n.t :filter_life_dates), :life_dates
    column (I18n.t :filter_owner) {|person| User.find(person.wf_owner).name rescue 0} if current_user.has_any_role?(:editor, :admin)
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

  show :title => proc{ active_admin_auth_show_title( @item.full_name, @item.life_dates, @item.id) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )

    render('jobs/jobs_monitor')

    @item = @arbre_context.assigns[:item]
    if @item.marc_source == nil
      render :partial => "marc/missing"
    else
      render :partial => "marc/show"
    end
    active_admin_embedded_source_list( self, person, !is_selection_mode? )

    # Box for publications referring to this person
    active_admin_embedded_link_list(self, person, Publication) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        context.column (I18n.t :filter_title_short), :short_name
        context.column (I18n.t :filter_author), :author
        context.column (I18n.t :filter_description), :description
        if !is_selection_mode?
          context.column "" do |publication|
            link_to "View", controller: :publications, action: :show, id: publication.id
          end
        end
      end
    end

    # Box for institutions referring to this person
    active_admin_embedded_link_list(self, person, Institution) do |context|
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

    active_admin_embedded_link_list(self, person, Holding) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        context.column (I18n.t :filter_siglum), :lib_siglum
        context.column (I18n.t :filter_source_name) {|hld| hld.source.std_title}
        context.column (I18n.t :filter_source_composer) {|hld| hld.source.composer}
        if !is_selection_mode?
          context.column "" do |hold|
            link_to I18n.t(:view_source), controller: :holdings, action: :show, id: hold.id
          end
        end
      end
    end

    active_admin_embedded_link_list(self, person, Work) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        context.column (I18n.t :filter_title), :title
        if !is_selection_mode?
          context.column "" do |work|
            link_to "View", controller: :works, action: :show, id: work.id
          end
        end
      end
    end

    active_admin_embedded_link_list(self, person, Person) do |context|
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

    active_admin_digital_object( self, @item ) if !is_selection_mode?
    active_admin_user_wf( self, person )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end

  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => person }
  end

  sidebar :libraries, :only => :show do
    render :partial => "people/library_pie"
  end

  ##########
  ## Edit ##
  ##########

  form :partial => "editor/edit_wide"

  sidebar :sections, :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
  end

end
