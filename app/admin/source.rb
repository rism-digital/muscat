ActiveAdmin.register Source do

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
  
  show do
    render :partial => "marc/show"
  end
  
=begin
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
=end
  
end
