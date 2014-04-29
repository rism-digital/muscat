ActiveAdmin.register Source do
  
  actions :all, except: [:edit] 

  #config.filters = false 

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
      options = params[:q]
      
      page = params.has_key?(:page) ? params[:page] : 1
      
      if options
        solr_results = Source.solr_search do
    
          if params.has_key?(:order)
            order = params[:order].include?("_asc") ? "asc" : "desc"
            field = params[:order].gsub("_#{order}", "")
     
            order_by field.underscore.to_sym, order.to_sym      
          end
    
          options.keys.each do |k|
            # to have it dynamic:
            #:fields => [k.to_sym]
            fields = [] # by default on all fields
            if k == :title_or_std_title_contains
              fields = [:title, :std_title]
            elsif k == :composer_contains
              fields = [:composer]
            elsif k == :lib_siglum_contains
              fields = [:lib_siglum]
            end

            if fields.empty?
              fulltext options[k]
            else
              fulltext options[k], :fields => fields
            end
          end

       
          paginate :page => page, :per_page => 30
        end
        @results = solr_results.results
      else
        #@results = Source.page(page).per(30)
        # Just use the default method
        super.index
        return
      end

      index! do |format|
        @sources = @results
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
  
#  config.clear_sidebar_sections!
#    sidebar :filters do
#      render partial: 'search'
#    end
  
  # temporary, to be replaced by Solr
  filter :title_or_std_title_contains, :as => :string
  filter :composer_contains, :as => :string
  filter :lib_siglum_contains, :label => "Library sigla contains", :as => :string
  filter :title_contains, :label => "Any field contains", :as => :string
  #filter :fulltext_in, :as => :string
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
