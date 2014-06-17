ActiveAdmin.register Library do
  
  menu :parent => "Authorities"

  collection_action :autocomplete_library_siglum, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :library, :siglum
    
    def permitted_params
      params.permit!
    end
    
    def show
      @library = Library.find(params[:id])
      @prev_item, @next_item, @prev_page, @next_page = Library.near_items_as_ransack(params, @library)
    end
    
    
    def index
      @results = Library.search_as_ransack(params)
      
      index! do |format|
        @libraries = @results
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
    column (I18n.t :filter_siglum), :siglum
    column (I18n.t :filter_location_and_name), :name
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
      row (I18n.t :filter_siglum) { |r| r.siglum }
      row (I18n.t :filter_address) { |r| r.address }
      row (I18n.t :filter_url) { |r| r.url }
      row (I18n.t :filter_phone) { |r| r.phone }
      row (I18n.t :filter_email) { |r| r.email }    
    end
    active_admin_embedded_source_list( self, library, params[:qe], params[:src_list_page] )
  end
  
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
 
  form do |f|
    f.inputs "Details" do
      f.input :siglum, :label => (I18n.t :filter_siglum)
      f.input :name, :label => (I18n.t :filter_name)
      f.input :address, :label => (I18n.t :filter_address)
    end
    f.inputs "Content" do
      f.input :url, :label => (I18n.t :filter_url)
      f.input :phone, :label => (I18n.t :filter_phone)
      f.input :email, :label => (I18n.t :filter_email)
    end
    f.actions
  end
  
end
