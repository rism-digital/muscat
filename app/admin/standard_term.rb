ActiveAdmin.register StandardTerm do

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
  filter :term_contains, :as => :string
  
  index do
    column (I18n.t :filter_term), :term
    column (I18n.t :filter_alternate_terms), :alternate_terms
    column (I18n.t :filter_sources), :ms_count
    actions
  end
  
  ##########
  ## Show ##
  ##########
  
  show do   
    attributes_table do
      row (I18n.t :filter_term) { |r| r.term }
      row (I18n.t :filter_alternate_terms) { |r| r.alternate_terms }
      row (I18n.t :filter_notes) { |r| r.notes }    
    end
    active_admin_embedded_source_list( self, standard_term, params[:q], params[:src_list_page] )
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
      f.input :term, :label => (I18n.t :filter_term) 
      f.input :alternate_terms, :label => (I18n.t :filter_alternate_terms)
    end
    f.actions
  end
  
end
