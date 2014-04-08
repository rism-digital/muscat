ActiveAdmin.register LiturgicalFeast do

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    def permitted_params
      params.permit!
    end
  end
  
  ###########
  ## Index ##
  ###########
  
  # temporary, to be replaced by Solr
  filter :name_contains, :as => :string
  
  index do
    column (I18n.t :filter_name), :name
    column (I18n.t :filter_sources), :src_count
    actions
  end
  
  ##########
  ## Show ##
  ##########
  
  show do   
    attributes_table do
      row (I18n.t :filter_name) { |r| r.name }
      row (I18n.t :filter_notes) { |r| r.notes }    
    end
    active_admin_embedded_source_list( self, liturgical_feast, params[:q], params[:src_list_page] )
  end
  
=begin
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
=end
  
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
