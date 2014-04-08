ActiveAdmin.register Person do
  
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
  filter :full_name_contains, :as => :string
  
  index do
    column (I18n.t :filter_full_name), :full_name
    column (I18n.t :filter_life_dates), :life_dates
    column (I18n.t :filter_sources), :ms_count
    actions
  end
  
  show do   
    attributes_table do
      row (I18n.t :filter_full_name) { |r| r.full_name }
      row (I18n.t :filter_life_dates) { |r| r.life_dates }
      row (I18n.t :filter_birth_place) { |r| r.birth_place }
      row (I18n.t :filter_gender) { |r| r.gender }
      row (I18n.t :filter_composer) { |r| r.composer }
      row (I18n.t :filter_source) { |r| r.source }
      row (I18n.t :filter_comments) { |r| r.comments }  
      row (I18n.t :filter_alternate_names) { |r| r.alternate_names }   
      row (I18n.t :filter_alternate_dates) { |r| r.alternate_dates }    
    end
    active_admin_views_helper_embedded_source_list( self, person, params[:q], params[:src_list_page] )
  end
  
=begin
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
=end

end
