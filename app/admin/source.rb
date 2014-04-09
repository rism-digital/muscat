ActiveAdmin.register Source do
  
   actions :all, except: [:edit] 

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
    
  end
  
  # temporary, to be replaced by Solr
  filter :composer_or_title_contains, :as => :string
  filter :lib_siglum_contains, :as => :string
  
  index do
    column (I18n.t :filter_composer), :composer
    column (I18n.t :filter_std_title), :std_title
    column (I18n.t :filter_title), :title
    column (I18n.t :filter_lib_siglum), :lib_siglum
    column (I18n.t :filter_shelf_mark), :shelf_mark
    actions
  end
  
  show :title => proc{ active_admin_source_show_title( @item.composer, @item.std_title, @item.id) } do
    # @item go from the controller is not available there. We need to get it from the @arbre_context
    @item = @arbre_context.assigns[:item]
    render :partial => "marc/show"
  end
  
=begin
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
=end
  
end
