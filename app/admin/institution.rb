ActiveAdmin.register Institution do
  
  menu :parent => "Authorities", url: ->{ institutions_path(locale: I18n.locale) }

  collection_action :autocomplete_institution_name, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :institution, :name
    
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
      @institution = Institution.find(params[:id])
      @prev_item, @next_item, @prev_page, @next_page = Institution.near_items_as_ransack(params, @institution)
    end
    
    def index
      @results = Institution.search_as_ransack(params)
      
      index! do |format|
        @institutions = @results
        format.html
      end
    end
    
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :name_equals, :label => "Any field contains", :as => :string
  
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
      row (I18n.t :filter_alternates) { |r| r.alternates }
      row (I18n.t :filter_notes) { |r| r.notes }  
    end
    active_admin_embedded_source_list( self, institution, params[:qe], params[:src_list_page] )
  end
  
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
  
  ##########
  ## Edit ##
  ##########
  
  form do |f|
    f.inputs do
      f.input :name, :label => (I18n.t :filter_name) 
      f.input :alternates, :label => (I18n.t :filter_alternates), :input_html => { :rows => 3 }
      f.input :notes, :label => (I18n.t :filter_notes) 
    end
    f.actions
  end
  
end
