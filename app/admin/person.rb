ActiveAdmin.register Person do
  
  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    def permitted_params
      params.permit!
    end
    
    def index
      @results = Person.search_as_ransack(params)
      
      index! do |format|
        @people = @results
        format.html
      end
    end
    
  end
  
  ###########
  ## Index ##
  ###########
  
  # temporary, to be replaced by Solr
  filter :full_name_contains, :as => :string
  
  index do
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_full_name), :full_name
    column (I18n.t :filter_life_dates), :life_dates
    column (I18n.t :filter_sources), :src_count
    actions
  end
  
  ##########
  ## Show ##
  ##########
  
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
    active_admin_embedded_source_list( self, person, params[:q], params[:src_list_page] )
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
      f.input :full_name, :label => (I18n.t :filter_full_name)
      f.input :life_dates, :label => (I18n.t :filter_life_dates) 
      f.input :birth_place, :label => (I18n.t :filter_birth_place)
      f.input :gender, :label => (I18n.t :filter_gender) 
      f.input :composer, :label => (I18n.t :filter_composer)
      f.input :source, :label => (I18n.t :filter_source)
      f.input :comments, :label => (I18n.t :filter_comments) 
      f.input :alternate_names, :label => (I18n.t :filter_alternate_names)
      f.input :alternate_dates, :label => (I18n.t :filter_alternate_dates)   
    end
    f.actions
  end

end
