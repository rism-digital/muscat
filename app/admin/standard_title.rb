ActiveAdmin.register StandardTitle do

  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_titles)}

  # Remove mass-delete action
  batch_action :destroy, false

  collection_action :autocomplete_standard_title_title, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do

    autocomplete :standard_title, :title, :extra_data => [:title], :string_boundary => true

    after_destroy :check_model_errors
    before_create do |item|
      item.user = current_user
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
      @standard_title = StandardTitle.find(params[:id])
      @prev_item, @next_item, @prev_page, @next_page = StandardTitle.near_items_as_ransack(params, @standard_title)
    end

    def index
      @results = StandardTitle.search_as_ransack(params)

      index! do |format|
        @standard_titles = @results
        format.html
      end
    end



  end

  # Include the folder actions
  include FolderControllerActions

  ###########
  ## Index ##
  ###########

  # Solr search all fields: "_equal"
  filter :title_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string

  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select,
         collection: proc{Folder.where(folder_type: "StandardTitle").collect {|c| [c.name, "folder_id:#{c.id}"]}}

  index do
    selectable_column
    column (I18n.t :filter_id), :id
    column (I18n.t :filter_title), :title
    column (I18n.t :filter_sources), :src_count
    actions
  end

  ##########
  ## Show ##
  ##########

  show do
    active_admin_navigation_bar( self )
    attributes_table do
      row (I18n.t :filter_title) { |r| r.title }
      row (I18n.t :filter_notes) { |r| r.notes }
    end
    active_admin_embedded_source_list( self, standard_title, params[:qe], params[:src_list_page] )
    active_admin_user_wf( self, standard_title )
    active_admin_navigation_bar( self )
  end

  sidebar I18n.t(:search_sources), :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end

  ##########
  ## Edit ##
  ##########

  form do |f|
    f.inputs do
      f.input :title, :label => (I18n.t :filter_title)
      f.input :notes, :label => (I18n.t :filter_notes)
      f.input :lock_version, :as => :hidden
    end
    f.actions
  end

end
