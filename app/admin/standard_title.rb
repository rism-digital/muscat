ActiveAdmin.register StandardTitle do

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
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
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :title_equals, :label => "Any field contains", :as => :string
  
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
    active_admin_embedded_source_list( self, standard_title, params[:q], params[:src_list_page] )
  end
  
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
  
  ##########
  ## Edit ##
  ##########
  
  form do |f|
    f.inputs do
      f.input :title, :label => (I18n.t :filter_title) 
      f.input :notes, :label => (I18n.t :filter_notes) 
    end
    f.actions
  end
  
end
