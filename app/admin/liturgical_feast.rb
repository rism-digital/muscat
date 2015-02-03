ActiveAdmin.register LiturgicalFeast do
  
  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_liturgical_feasts)}

  # Remove mass-delete action
  batch_action :destroy, false
  
  collection_action :autocomplete_liturgical_feast_name, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :liturgical_feast, :name
    
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
      @liturgical_feast = LiturgicalFeast.find(params[:id])
      @prev_item, @next_item, @prev_page, @next_page = LiturgicalFeast.near_items_as_ransack(params, @liturgical_feast)
    end
    
    def index
      @results = LiturgicalFeast.search_as_ransack(params)
      
      index! do |format|
        @liturgical_feasts = @results
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
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "LiturgicalFeast").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  
  index do
    selectable_column
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_name), :name
    column (I18n.t :filter_sources), :src_count
    actions
  end
  
  ##########
  ## Show ##
  ##########
  
  show do
    active_admin_navigation_bar( self )
    attributes_table do
      row (I18n.t :filter_name) { |r| r.name }
      row (I18n.t :filter_notes) { |r| r.notes } 
    end
    active_admin_embedded_source_list( self, liturgical_feast, params[:qe], params[:src_list_page] )
    active_admin_user_wf( self, liturgical_feast )
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
      f.input :name, :label => (I18n.t :filter_name)
      f.input :notes, :label => (I18n.t :filter_notes) 
    end
    f.actions
  end
  
end
