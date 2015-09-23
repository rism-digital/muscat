ActiveAdmin.register Folder do
  
  menu :label => proc {I18n.t(:menu_folders)}

  # Remove mass-delete action
  batch_action :destroy, false
  
  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
        
    after_destroy :check_model_errors
    before_create do |item|
      item.user = current_user
    end
    
    def check_model_errors(object)
      
      # Look in the saved filters for this controller
      # relative to the folder type of the deleted folder
      # if it was filtered by folder. If it was remove it
      controller =  object.folder_type.underscore.downcase.pluralize
      if session[:last_search_filter] && session[:last_search_filter][controller]
        params_q =  session[:last_search_filter][controller]
        if params_q.include?(:id_with_integer)
          params_q.delete(:id_with_integer)
        end
      end
      
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end
    
    def permitted_params
      params.permit!
    end
    
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  
  index :download_links => false do |ad|
    selectable_column
    column (I18n.t :filter_name), :name
    column (I18n.t :filter_folder_type), :folder_type
    column ("Items")  {|folder| folder.folder_items.count}
    actions
  end
  
  ##########
  ## Show ##
  ##########
  
  show do
    active_admin_navigation_bar( self )
    attributes_table do
      row (I18n.t :filter_name) { |r| r.name }
      row (I18n.t :filter_folder_type) { |r| r.folder_type }
    end
    
    panel folder.folder_type.pluralize, :class => "muscat_panel"  do
      
      fitems = folder.folder_items
      
      paginated_collection(fitems.page(params[:src_list_page]).per(10), param_name: 'src_list_page',  download_links: false) do
        table_for(collection) do |cr|
          column ("Name") {|fitem| fitem.item.name}
          column ("Id") {|fitem| fitem.item.id}
          column "" do |fitem|
            link_to "View", controller: fitem.item.class.to_s.pluralize.underscore.downcase.to_sym, action: :show, id: fitem.item.id
          end
        end
      end
    end
    
  end

  ##########
  ## Edit ##
  ##########
  
  sidebar :actions, :only => [:edit, :new] do
    render("editor/section_sidebar_save") # Calls a partial
  end

  form do |f|
    f.inputs do
      f.input :name, :label => (I18n.t :filter_name)
    end
  end
  
end
