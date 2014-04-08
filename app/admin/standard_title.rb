ActiveAdmin.register StandardTitle do

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    def permitted_params
      params.permit!
    end
  end
  
  # temporary, to be replaced by Solr
  filter :title_contains, :as => :string
  
  index do
    column (I18n.t :filter_title), :title
    column (I18n.t :filter_sources), :ms_count
    actions
  end
  
  show do   
    attributes_table do
      row (I18n.t :filter_title) { |r| r.title }
      row (I18n.t :filter_notes) { |r| r.notes }  
    end
    active_admin_views_helper_embedded_source_list( self, catalogue, params[:q], params[:src_list_page] )
  end
  
=begin
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
=end
  
end
