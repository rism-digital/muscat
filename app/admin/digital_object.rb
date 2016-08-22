ActiveAdmin.register DigitalObject do

  # Hide the menu
  menu false

  # Remove mass-delete action
  batch_action :destroy, false
  
  # Remove all action items
  config.clear_action_items!
  
  # Remove creation option (only possible from source)
  actions :all, :except => [:new]
  
  controller do
    def permitted_params
      params.permit! #params.permit :description, :attachment
    end
    
    before_create do |item|
      item.user = current_user
    end
    
    def show
      begin
        @digital_object = DigitalObject.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Digital object #{params[:id]})" }
        return
      end
    end
    
    # Redirect to the resource show page after comment creation
    def create
      create! do |success, failure|
        success.html do
          redirect_to admin_source_path(params[:digital_object][:source_id])
          return
        end
        failure.html do
          flash[:error] = "The digital object could not be created"
          redirect_to admin_source_path(params[:digital_object][:source_id])
          return
        end
      end
    end
    
    def destroy
      obj = DigitalObject.find(params[:id])
      destroy_redirect = obj ? admin_source_path(obj.source_id) : admin_sources_url
      destroy! { redirect_to destroy_redirect and return }
    end
    
  end
  
  ###########
  ## Index ##
  ###########
  
  filter :description, :label => proc {I18n.t(:filter_description)}
  filter :attachment_file_name, :label => proc {I18n.t(:filter_file_name)}
  filter :attachment_file_size, :label => proc {I18n.t(:filter_file_size)}
  filter :attachment_content_type, :label => proc {I18n.t(:filter_content_type)}
  filter :attachment_updated_at, :label => proc {I18n.t(:updated_at)}
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    id_column
    column (I18n.t :filter_description), :description
    column (I18n.t :filter_file_name), :attachment_file_name
    column (I18n.t :filter_file_size) {|obj| filesize_to_human(obj.attachment_file_size) if obj.attachment_file_size}
    column (I18n.t :filter_content_type), :attachment_content_type
    active_admin_muscat_actions( self )
  end
  
  sidebar :actions, :only => :index do
    render :partial => "activeadmin/filter_workaround"
    render :partial => "activeadmin/section_sidebar_index"
  end
  
  ##########
  ## Show ##
  ##########
  
  show :title => proc{ active_admin_digital_object_show_title( @digital_object.description, @digital_object.id) } do |ad|
    attributes_table do
      row (I18n.t :filter_description) { |r| r.description } 
      row (I18n.t :filter_source) do 
        link_to(ad.source.id, admin_source_path(ad.source)) if ad.source
      end
    end
    if ad.attachment_file_size
      panel (I18n.t :filter_image) do
        image_tag(ad.attachment.url(:maximum))
      end
    end
    attributes_table do
      row (I18n.t :filter_file_name) { |r| link_to( r.attachment_file_name, r.attachment.url(:original, false), :target => "_blank") if r.attachment_file_size}
      row (I18n.t :filter_file_size) {|r| filesize_to_human(r.attachment_file_size) if r.attachment_file_size}
      row (I18n.t :filter_content_type) { |r| r.attachment_content_type }
      row (I18n.t :updated_at) { |r| r.attachment_updated_at }
      row (I18n.t :filter_owner) { |r| r.user.name } if ( ad.user )
    end
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => digital_object }
  end
  
  ##########
  ## Edit ##
  ##########
  
  form :html => {:multipart => true} do |f|
    f.inputs do
      f.input :description,:label => I18n.t(:filter_description)
      f.input :attachment, as: :file, :label => I18n.t(:filter_image)
      f.input :lock_version, :as => :hidden
    end
  end

  sidebar :actions, :only => [:edit] do
    render :partial => "activeadmin/section_sidebar_edit", :locals => { :item => digital_object }
  end
  
end
