ActiveAdmin.register LiturgicalFeast do

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
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
      row (I18n.t :filter_notes) { |r| r.notes }    
    end
    active_admin_embedded_source_list( self, liturgical_feast, params[:qe], params[:src_list_page] )
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
      f.input :notes, :label => (I18n.t :filter_notes) 
    end
    f.actions
  end
  
end
