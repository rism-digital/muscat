ActiveAdmin.register_page "doc" do
  menu :parent => "admin_menu", :label => proc {I18n.t(:menu_marc_documentation)}
  
  controller do
    def index
      params[:model] = "Source" if !params[:model]
      @model_name = params[:model].downcase
      klass = params[:model].classify.safe_constantize
      @model = klass != nil ? klass.new : nil
    end
  end
  
  content title: proc{ I18n.t(:menu_marc_documentation) + " - " + @model.class.name } do
    render partial: 'fields'
  end
  
  ###########
  ## Index ##
  ###########
  
  sidebar :models, :class => "sidebar_tabs", :only => [:index] do
    # no idea why the I18n.locale is not set by set_locale in the ApplicationController
    I18n.locale = session[:locale]
    render("doc_sidebar") # Calls a partial
  end
  
end