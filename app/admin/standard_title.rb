ActiveAdmin.register StandardTitle do

  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_titles)}

  # Remove mass-delete action
  batch_action :destroy, false
  
  collection_action :autocomplete_standard_title_title, :method => :get

  breadcrumb do
    active_admin_muscat_breadcrumb
  end
    
  action_item :view, only: :show, if: proc{ is_selection_mode? } do
    active_admin_muscat_select_link( standard_title )
  end

  action_item :view, only: [:index, :show], if: proc{ is_selection_mode? } do
    active_admin_muscat_cancel_link
  end

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
        @standard_title = StandardTitle.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (StandardTitle #{params[:id]})" }
      end
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
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_title), :title
    column (I18n.t :filter_sources), :src_count
    active_admin_muscat_actions( self )
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
    active_admin_embedded_source_list( self, standard_title, params[:qe], params[:src_list_page], !is_selection_mode? )
    active_admin_user_wf( self, standard_title )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
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
  end
  
  sidebar :actions, :only => [:edit, :new] do
    render("editor/section_sidebar_save") # Calls a partial
  end
  
end
