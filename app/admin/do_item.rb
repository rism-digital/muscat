ActiveAdmin.register DoItem do
  # Temporary hide menu item because place model has to be configured first
  menu false
  #menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_places)}

  # Remove mass-delete action
  batch_action :destroy, false
  
  # Don't forget to add the image attribute (here thumbnails) to permitted_params
  controller do
    def permitted_params
      params.permit!
    end
  end

  form :html => {:multipart => true} do |f|
    f.inputs do
      f.input :image, as: :file, hint: (f.template.image_tag(f.object.image.url(:thumb)) if f.object.image?)
    end
    f.actions
  end

  show do |ad|
      attributes_table do
        row :title
        row :image do
          image_tag(ad.image.url(:original))
        end
        # Will display the image on show object page
      end
    end
end
