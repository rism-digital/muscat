ActiveAdmin.register StandardTerm do

  menu :parent => "Authorities"

  collection_action :autocomplete_standard_term_term, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :standard_term, :term
    
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
      @standard_term = StandardTerm.find(params[:id])
      @prev_item, @next_item, @prev_page, @next_page = StandardTerm.near_items_as_ransack(params, @standard_term)
    end
    
    
    def index
      @results = StandardTerm.search_as_ransack(params)
      
      index! do |format|
        @standard_terms = @results
        format.html
      end
    end
    
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :term_equals, :label => "Any field contains", :as => :string
  
  index do
    selectable_column
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_term), :term
    column (I18n.t :filter_alternate_terms), :alternate_terms
    column (I18n.t :filter_sources), :src_count
    actions
  end
  
  ##########
  ## Show ##
  ##########
  
  show :title => :term do
    active_admin_navigation_bar( self ) 
    attributes_table do
      row (I18n.t :filter_term) { |r| r.term }
      row (I18n.t :filter_alternate_terms) { |r| r.alternate_terms }
      row (I18n.t :filter_notes) { |r| r.notes }    
    end
    active_admin_embedded_source_list( self, standard_term, params[:qe], params[:src_list_page] )
  end
  
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
  
  ##########
  ## Edit ##
  ##########
  
  form do |f|
    f.inputs do
      f.input :term, :label => (I18n.t :filter_term) 
      f.input :alternate_terms, :label => (I18n.t :filter_alternate_terms), :input_html => { :rows => 3 }
      f.input :notes, :label => (I18n.t :filter_notes) 
    end
    f.actions
  end
  
end
