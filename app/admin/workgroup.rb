ActiveAdmin.register Workgroup do
  
  menu :parent => "admin_menu", :label => proc {I18n.t(:menu_workgroups)}

  collection_action :autocomplete_workgroup_name, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :workgroup, :name
    
    after_destroy :check_model_errors
    
    def check_model_errors(object)
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end
    
    def permitted_params
      params.permit!
    end
    
    def show
      @workgroup = Workgroup.find(params[:id])
      @prev_item, @next_item, @prev_page, @next_page = Workgroup.near_items_as_ransack(params, @workgroup)
    end
    
    def index
      #@results = Workgroup.search_as_ransack(params)
      
      index! do |format|
        #@workgroups = @results
        format.html
      end
    end
    
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  
  index :download_links => false do
    selectable_column
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_name), :name
    column (I18n.t :filter_pattern), :libpatterns
    column I18n.t(:filter_connected_libraries), :workgroups do |wg|
             wg.institutions.map(&:siglum).join(", ").html_safe
       end

    #column (I18n.t :filter_sources), :src_count
    actions
  end
  
  ##########
  ## Show ##
  ##########
  
  show do
    active_admin_navigation_bar( self )
    attributes_table do
      row (I18n.t :filter_name) { |r| r.name }
      row (I18n.t :filter_pattern) { |r| r.libpatterns }
      row I18n.t(:connected_libraries) do |n|
             workgroup.institutions.map(&:siglum).join(", ").html_safe
               end
     # row (I18n.t :filter_alternates) { |r| r.alternates }
     # row (I18n.t :filter_notes) { |r| r.notes }  
    end
    #active_admin_embedded_source_list( self, workgroup, params[:qe], params[:src_list_page] )
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
      f.input :libpatterns, :label => (I18n.t :filter_pattern)
      #f.input :alternates, :label => (I18n.t :filter_alternates), :input_html => { :rows => 3 }
      #f.input :notes, :label => (I18n.t :filter_notes) 
    end
  end
  
  sidebar :actions, :only => [:edit, :new] do
    render("editor/section_sidebar_save") # Calls a partial
  end
  
end
