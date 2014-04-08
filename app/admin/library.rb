ActiveAdmin.register Library do

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    def permitted_params
      params.permit!
    end
  end
  
  # temporary, to be replaced by Solr
  filter :siglum_or_name_starts_with, :as => :string
  filter :address
  
  index do
    column (I18n.t :filter_siglum), :siglum
    column (I18n.t :filter_location_and_name), :name
    column (I18n.t :filter_sources), :ms_count
    actions
  end
  
  show do   
    attributes_table do
      row (I18n.t :filter_name) { |r| r.name }
      row (I18n.t :filter_siglum) { |r| r.siglum }
      row (I18n.t :filter_address) { |r| r.address }
      row (I18n.t :filter_url) { |r| r.url }
      row (I18n.t :filter_phone) { |r| r.phone }
      row (I18n.t :filter_email) { |r| r.email }    
    end
    active_admin_views_helper_embedded_source_list( self, library, params[:q], params[:src_list_page] )
  end
 
  form do |f|
    f.inputs "Details" do
      f.input :siglum
      f.input :name
      f.input :address
    end
    f.inputs "Content" do
      f.input :url
      f.input :phone
      f.input :email
    end
    f.actions
  end

=begin
  sidebar "Search sources", :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
=end
  
end
