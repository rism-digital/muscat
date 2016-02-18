ActiveAdmin.register DigitalObject do

  # Hide the menu
  menu false

  # Remove mass-delete action
  batch_action :destroy, false
  
  # Remove creation option (only possible from source)
  actions :all, :except => [:new]
  
  controller do
    def permitted_params
      params.permit! #params.permit :description, :attachment
    end
    
    before_create do |item|
      item.user = current_user
    end
    
    # Redirect to the resource show page after comment creation
    def create
      create! do |success, failure|
        success.html do
          redirect_to admin_source_path(params[:digital_object][:source_id])
          return
        end
        failure.html do
          flash[:error] = I18n.t 'active_admin.comments.errors.empty_text'
          redirect_to admin_source_path(params[:digital_object][:source_id])
        end
      end
    end
    
  end
  
  ###########
  ## Index ##
  ###########
  
  filter :description
  filter :attachment_file_name
  filter :attachment_file_size
  filter :attachment_content_type
  filter :attachment_updated_at
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    id_column
    column (I18n.t :filter_name), :description
    column (I18n.t :filter_author), :attachment_file_name
    column (I18n.t :filter_sources), :attachment_file_size
    column (I18n.t :filter_sources), :attachment_content_type
    active_admin_muscat_actions( self )
  end
  
  ##########
  ## Show ##
  ##########

  show do |ad|
    attributes_table do
      row :description
      row :source do 
        link_to(ad.source.id, admin_source_path(ad.source)) if ad.source
      end
      row :attachment do
        image_tag(ad.attachment.url(:original))
      end
      row :attachment_file_name
      row :attachment_file_size
      row :attachment_content_type
      row :attachment_updated_at
    end
  end
  
  ##########
  ## Edit ##
  ##########
  
  form :html => {:multipart => true} do |f|
    f.inputs do
      f.input :description
      f.input :attachment, as: :file
      f.input :lock_version, :as => :hidden
    end
  end

  sidebar :actions, :only => [:edit] do
    render("editor/section_sidebar_save") # Calls a partial
  end
  
end
