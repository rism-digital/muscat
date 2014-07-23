ActiveAdmin.register Source do
  
  collection_action :autocomplete_source_std_title, :method => :get
  
  menu :priority => 10

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :source, :std_title
    
    def permitted_params
      params.permit!
    end
    
    def show
      @item = Source.find(params[:id])
      @editor_profile = EditorConfiguration.get_show_layout @item
      @prev_item, @next_item, @prev_page, @next_page = Source.near_items_as_ransack(params, @item)
    end

    def edit
      @item = Source.find(params[:id])
      @editor_profile = EditorConfiguration.get_applicable_layout @item
      @page_title = "Edit #{@editor_profile.name} [#{@item.id}]"
    end

    def index
      @results = Source.search_as_ransack(params)     
      index! do |format|
       @sources = @results
        format.html
      end
    end

    def new
      @source = Source.new
      @based_on = String.new

      if (!params[:existing_title] || params[:existing_title].empty?) && (!params[:new_type] || params[:new_type].empty?)
        redirect_to action: :select_new_template
        return
      end

      if params[:existing_title] and !params[:existing_title].empty?
        @based_on = "exsiting title"
        base_item = Source.find(params[:existing_title])
        new_marc = MarcSource.new(base_item.marc.marc_source)
        new_marc.load_source false # this will need to be fixed
        new_marc.first_occurance("001").content = "__TEMP__"
        @source.marc = new_marc
      elsif File.exists?("#{Rails.root}/config/marc/#{RISM::BASE}/source/" + params[:new_type] + '.marc')
        @based_on = params[:new_type]
        new_marc = MarcSource.new(File.read("#{Rails.root}/config/marc/#{RISM::BASE}/source/" +params[:new_type] + '.marc'))
        new_marc.load_source false # this will need to be fixed
        @source.marc = new_marc
      end
      @page_title = "New source"
      @editor_profile = EditorConfiguration.get_applicable_layout @source
      #To transmit correctly @item we need to have @source initialized
      @item = @source
    end

  end
  
  # Include the MARC extensions
  include MarcControllerActions
  
  collection_action :select_new_template, :method => :get

  
  #scope :all, :default => true 
  #scope :published do |sources|
  #  sources.where(:wf_stage => 'published')
  #end
  
  ###########
  ## Index ##
  ###########  

  # filers
  filter :title_contains, :as => :string
  filter :std_title_contains, :as => :string
  filter :composer_contains, :as => :string
  filter :lib_siglum_contains, :label => "Library sigla contains", :as => :string
  filter :title_equals, :label => "Any field contains", :as => :string
  
  index do
    selectable_column
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_composer), :composer
    column (I18n.t :filter_std_title), :std_title
    column (I18n.t :filter_title), :title
    column (I18n.t :filter_lib_siglum), :lib_siglum
    column (I18n.t :filter_shelf_mark), :shelf_mark
    actions
  end
  
  ##########
  ## Show ##
  ##########
  
  show :title => proc{ active_admin_source_show_title( @item.composer, @item.std_title, @item.id) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    @item = @arbre_context.assigns[:item]
    render :partial => "marc/show"
    active_admin_navigation_bar( self )
  end
  
  ##########
  ## Edit ##
  ##########
  
  sidebar "Sections", :class => "sidebar_tabs", :only => [:edit, :new] do
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
