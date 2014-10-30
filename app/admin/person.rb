ActiveAdmin.register Person do

  menu :parent => "indexes_menu", url: ->{ people_path(locale: I18n.locale) }, :label => proc {I18n.t(:menu_people)}

  collection_action :autocomplete_person_full_name, :method => :get
  
  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :person, :full_name
    
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
      @item = Person.find(params[:id])
      @editor_profile = EditorConfiguration.get_applicable_layout @item
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"
    end
    
    def show
      @item = @person = Person.find(params[:id])
      @editor_profile = EditorConfiguration.get_show_layout @person
      @prev_item, @next_item, @prev_page, @next_page = Person.near_items_as_ransack(params, @person)
    end
    
    def index
      @results = Person.search_as_ransack(params)
      
      index! do |format|
        @people = @results
        format.html
      end
    end
    
    def new
      @person = Person.new
      
      new_marc = MarcPerson.new(File.read("#{Rails.root}/config/marc/#{RISM::BASE}/person/default.marc"))
      new_marc.load_source false # this will need to be fixed
      @person.marc = new_marc

      @page_title = I18n.t(:new_person)
      @editor_profile = EditorConfiguration.get_applicable_layout @person
      #To transmit correctly @item we need to have @source initialized
      @item = @person
    end

  end
  
  # Include the MARC extensions
  include MarcControllerActions
    
  ###########
  ## Index ##
  ###########
  
  # temporary, to be replaced by Solr
  filter :full_name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
#  filter :name_contains, :as => :string
  
  index do
    selectable_column
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_full_name), :full_name
    column (I18n.t :filter_life_dates), :life_dates
    column (I18n.t :filter_sources), :src_count
    actions
  end
  
  ##########
  ## Show ##
  ##########
  
  show :title => proc{ active_admin_source_show_title( @item.full_name, @item.life_dates, @item.id) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    @item = @arbre_context.assigns[:item]
    if @item.marc_source == nil
      render :partial => "marc_missing"
    else
      render :partial => "marc/show"
    end
    active_admin_embedded_source_list( self, person, params[:qe], params[:src_list_page] )
    active_admin_navigation_bar( self )
  end
  
  sidebar I18n.t(:search_sources), :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
  
  ##########
  ## Edit ##
  ##########
  
  sidebar I18n.t(:sections), :only => [:edit, :new] do
    render("editor/section_sidebar") # Calls a partial
  end
  
  form do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_edition_bar( self )
    @item =  @arbre_context.assigns[:item]
    render :partial => "editor/edit_wide"
    active_admin_submit_bar( self )
  end

end
