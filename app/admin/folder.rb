ActiveAdmin.register Folder do
  
  menu url: ->{ folders_path(locale: I18n.locale) }, :label => proc {I18n.t(:menu_folders)}

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
        
    after_destroy :check_model_errors
    
    def check_model_errors(object)
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
  
  index do |ad|
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
      
      paginated_collection(fitems.page(params[:page]).per(10), param_name: 'src_list_page',  download_links: false) do
        table_for(collection) do |cr|
          column ("Name") {|fitem| fitem.item.name}
          column ("Id") {|fitem| fitem.item.id}
          column "" do |fitem|
            link_to "View", controller: :sources, action: :show, id: fitem.item.id
          end
        end
      end
    end
    
  end
  
 
  form do |f|
    f.inputs I18n.t(:contents) do
      f.input :name, :label => (I18n.t :filter_name)
    end
    f.actions
  end
  
end
