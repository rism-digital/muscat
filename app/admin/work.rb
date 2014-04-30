ActiveAdmin.register Work do
  
  menu false

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    def permitted_params
      params.permit!
    end
  end
  
  ###########
  ## Index ##
  ###########
  
  # temporary, to be replaced by Solr
  filter :title_or_form_contains, :as => :string
  
end
