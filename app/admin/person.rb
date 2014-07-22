ActiveAdmin.register Person do

  menu :parent => "Authorities"

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
      @page_title = "Edit #{@editor_profile.name} [#{@item.id}]"
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
    

  end
  
  ###########
  ## Index ##
  ###########
  
  # temporary, to be replaced by Solr
  filter :full_name_equals, :label => "Any Field contains", :as => :string
  
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
 
=begin 
  show do
    active_admin_navigation_bar( self )   
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
    active_admin_embedded_source_list( self, person, params[:qe], params[:src_list_page] )
  end
=end
  
  show :title => proc{ active_admin_source_show_title( @item.full_name, @item.life_dates, @item.id) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    @item = @arbre_context.assigns[:item]
    render :partial => "marc/show"
    active_admin_navigation_bar( self )
  end
  
  sidebar "Search people", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
  
  ##########
  ## Edit ##
  ##########

=begin  
  form do |f|
    f.inputs do
      f.semantic_errors :base
      f.input :full_name, :label => (I18n.t :filter_full_name)
      f.input :life_dates, :label => (I18n.t :filter_life_dates) 
      f.input :birth_place, :label => (I18n.t :filter_birth_place)
      f.input :gender, :label => (I18n.t :filter_gender) 
      f.input :composer, :label => (I18n.t :filter_composer)
      f.input :source, :label => (I18n.t :filter_source)
      f.input :comments, :label => (I18n.t :filter_comments)
      f.input :alternate_names, :label => (I18n.t :filter_alternate_names), :input_html => { :rows => 3 }
      f.input :alternate_dates, :label => (I18n.t :filter_alternate_dates), :input_html => { :rows => 3 }  
    end
    f.actions
  end
=end
  
  sidebar "Sections", :only => [:edit, :new] do
    render("editor/section_sidebar") # Calls a partial
  end
  
  form do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_edition_bar( self )
    @item =  @arbre_context.assigns[:item]
    render :partial => "editor/edit_wide"
    active_admin_edition_bar( self )
  end

end
