ActiveAdmin.register Catalogue do
  
  menu :parent => "indexes_menu", url: ->{ catalogues_path(locale: I18n.locale) }, :label => proc {I18n.t(:menu_catalogues)}

  collection_action :autocomplete_catalogue_name, :method => :get

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :catalogue, :name
    
    after_destroy :check_model_errors
    
    def check_model_errors(object)
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end
    
    def permitted_params
      params.permit!
    end
    
    def edit
      @item = Catalogue.find(params[:id])
      @editor_profile = EditorConfiguration.get_applicable_layout @item
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"
    end

    def show
      @catalogue = Catalogue.find(params[:id])
      @editor_profile = EditorConfiguration.get_show_layout @catalogue
      @prev_item, @next_item, @prev_page, @next_page = Catalogue.near_items_as_ransack(params, @catalogue)
    end
    
    def index
      @results = Catalogue.search_as_ransack(params)
      
      index! do |format|
        @catalogues = @results
        format.html
      end
    end
    
  end
  
  include MarcControllerActions
  ###########
  ## Index ##
  ###########
  
  #scope :all, :default => true 
  #scope :published do |catalogues|
  #  catalogues.where(:wf_stage => 'published')
  #end
  
  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  
  index do
    selectable_column
    column (I18n.t :filter_id), :id    
    column (I18n.t :filter_name), :name
    column (I18n.t :filter_name), :revue_title
    column (I18n.t :filter_author), :author
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
      row (I18n.t :filter_author) { |r| r.author }
      row (I18n.t :filter_description) { |r| r.description }
      row (I18n.t :filter_revue_title) { |r| r.revue_title }
      row (I18n.t :filter_volume) { |r| r.volume }
      row (I18n.t :filter_date) { |r| r.date }
      row (I18n.t :filter_pages) { |r| r.pages }     
    end
    active_admin_embedded_source_list( self, catalogue, params[:qe], params[:src_list_page] )
  end
  
begin  
  sidebar I18n.t(:search_sources), :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
end
  
  ##########
  ## Edit ##
  ##########
  
  form do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_edition_bar( self )
    @item =  @arbre_context.assigns[:item]
    render :partial => "editor/edit_wide"
    active_admin_submit_bar( self )
  end
  
end
