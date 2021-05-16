ActiveAdmin.register Place do
  # Temporary hide menu item because place model has to be configured first
  # menu false
  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_places)}

  # Remove mass-delete action
  batch_action :destroy, false

  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100]

  collection_action :autocomplete_place_name, :method => :get

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do

    autocomplete :place, :name

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

    def show
      begin
        @place = Place.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Place #{params[:id]})" }
        return
      end
      @prev_item, @next_item, @prev_page, @next_page = Place.near_items_as_ransack(params, @place)

      @jobs = @place.delayed_jobs
    end

    def index
      @results, @hits = Place.search_as_ransack(params)
      index! do |format|
        @places = @results
        format.html
      end
    end

    # redirect update failure for preserving sidebars
    def update
      update! do |success,failure|
        success.html { redirect_to collection_path }
        failure.html { redirect_back fallback_location: root_path, flash: { :error => "#{I18n.t(:error_saving)}" } }
      end
    end

    # redirect create failure for preserving sidebars
    def create
      create! do |success,failure|
        failure.html { redirect_back fallback_location: root_path, flash: { :error => "#{I18n.t(:error_saving)}" } }
      end
    end

  end

  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(params[:id], Place, :referring_sources))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end

  ###########
  ## Index ##
  ###########

  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string

  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
    collection: proc{Folder.where(folder_type: "Place").collect {|c| [c.name, "folder_id:#{c.id}"]}}

  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_name), :name
    column (I18n.t :filter_country), :country
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

  show do
    active_admin_navigation_bar( self )
    render('jobs/jobs_monitor')
    attributes_table do
      row (I18n.t :filter_name) { |r| r.name }
      row (I18n.t :filter_alternate_terms) { |r| r.alternate_terms }
      row (I18n.t :filter_topic) { |r| r.topic }
      row (I18n.t :filter_sub_topic) { |r| r.sub_topic }
      row (I18n.t :filter_country) { |r| r.country }
      row (I18n.t :filter_district) { |r| r.district }    
      row (I18n.t :filter_notes) { |r| r.notes }    
    end
    active_admin_embedded_source_list( self, place, !is_selection_mode? )
    
    # Box for people referring to this place
    active_admin_embedded_link_list(self, place, Person) do |context|
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
    
    # Box for publications referring to this place
    active_admin_embedded_link_list(self, place, Publication) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        context.column (I18n.t :filter_title_short), :short_name
        context.column (I18n.t :filter_author), :author
        context.column (I18n.t :filter_title), :title
        if !is_selection_mode?
          context.column "" do |publication|
            link_to "View", controller: :publications, action: :show, id: publication.id
          end
        end
      end
    end 

    # Box for institutions referring to this place
    active_admin_embedded_link_list(self, place, Institution) do |context|
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

    # Box for holdings referring to this place
    active_admin_embedded_link_list(self, place, Holding) do |context|
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
    
    active_admin_user_wf( self, place )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end

  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => place }
  end

  ##########
  ## Edit ##
  ##########

  form do |f|
    f.inputs do
      f.input :name, :label => (I18n.t :filter_name)
      f.input :alternate_terms, :label => (I18n.t :filter_alternate_terms)
      f.input :topic, :label => (I18n.t :filter_topic)
      f.input :sub_topic, :label => (I18n.t :filter_sub_topic)
      f.input :country, :label => (I18n.t :filter_country), :as => :string # otherwise country-select assumed
      f.input :district, :label => (I18n.t :filter_district)
      f.input :notes, :label => (I18n.t :filter_notes)
      f.input :lock_version, :as => :hidden
    end
  end

  sidebar :actions, :only => [:edit, :new, :update] do
    render :partial => "activeadmin/section_sidebar_edit", :locals => { :item => place }
  end

end
