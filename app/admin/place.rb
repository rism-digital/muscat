ActiveAdmin.register Place do

  menu :parent => "indexes_menu", url: ->{ places_path(locale: I18n.locale) }, :label => proc {I18n.t(:menu_places)}

  collection_action :autocomplete_place_name, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :place, :name
    
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
      @place = Place.find(params[:id])
      @prev_item, @next_item, @prev_page, @next_page = Place.near_items_as_ransack(params, @place)
    end
    
    def index
      @results = Place.search_as_ransack(params)
      
      index! do |format|
        @places = @results
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
  
  index do
    selectable_column
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_name), :name
    column (I18n.t :filter_country), :country
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
      row (I18n.t :filter_country) { |r| r.country }
      row (I18n.t :filter_district) { |r| r.district }    
    end
    active_admin_embedded_source_list( self, place, params[:qe], params[:src_list_page] )
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
      f.input :country, :label => (I18n.t :filter_country), :as => :string # otherwise country-select assumed
      f.input :district, :label => (I18n.t :filter_district) 
    end
    f.actions
  end

end
