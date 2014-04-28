ActiveAdmin.register Source do
  
  actions :all, except: [:edit] 

  config.filters = false 

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    def permitted_params
      params.permit!
    end
    
    def show
      @editor_profile = EditorConfiguration.get_show_layout
      @item = Source.find(params[:id])
    end
    
    def index
      options = params[:filters]
      
      @sunspot_search = Source.solr_search do |s|
       # FIXME For experimenting
       if options
         options.keys.each do |k|
           ap k
           ap options[k]
           s.fulltext options[k], :fields => [k.to_sym]
         end
       end
      end
      
      index! do |format|
       @sources = @sunspot_search.results
       format.html
      end
    end
    
  end
  
  #scope :all, :default => true 
  #scope :published do |sources|
  #  sources.where(:wf_stage => 'published')
  #end
  
  ###########
  ## Index ##
  ###########
  
  config.clear_sidebar_sections!
 
    sidebar :filters do
      render partial: 'search'
    end
  
  # temporary, to be replaced by Solr
  #filter :composer_or_title_contains, :as => :string
  #filter :lib_siglum_contains, :as => :string
  
  index do
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
    # @item go from the controller is not available there. We need to get it from the @arbre_context
    @item = @arbre_context.assigns[:item]
    render :partial => "marc/show"
  end
  
end
