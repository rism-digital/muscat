ActiveAdmin.register DigitalObject do

  # Hide the menu
  menu :parent => "indexes_menu", :label => proc {I18n.t(:digital_objects)}

  # Remove mass-delete action
  batch_action :destroy, false
  
  # Remove all action items
  config.clear_action_items!
  
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
          # If we have a new_object_link_type/id, also create the object link - See the DigitalObjectLink for
          # the fake accessors and the form below for the hidden fields
          if (params[:digital_object][:new_object_link_type] && params[:digital_object][:new_object_link_id] &&
             !params[:digital_object][:new_object_link_type].empty? && !params[:digital_object][:new_object_link_id].empty?
            )
            dol = DigitalObjectLink.new(
              object_link_type: params[:digital_object][:new_object_link_type],
              object_link_id: params[:digital_object][:new_object_link_id],
              user: resource.user,
              digital_object_id: resource.id)
              
            dol.save!
          end
          redirect_to admin_digital_object_path(resource.id)
          return
        end
#        failure.html do
#          flash[:error] = "The digital object could not be created"
#          redirect_to collection_path
#          return
#        end
      end
    end
    
  end
  
  member_action :add_item, method: :get do
    if can?(:create, DigitalObjectLink)
      #begin
        dol = DigitalObjectLink.new(object_link_type: params[:object_model], object_link_id: params[:object_id],
                                    user: current_user, digital_object_id: params[:id])
        dol.save!
    
        redirect_to resource_path(params[:id]), notice: "Item added successfully, #{params[:object_model]}: #{params[:object_id]}"
      #rescue
      #  redirect_to resource_path(params[:id]), error: "Could not add, #{params[:object_model]}: #{params[:object_id]}"
      #end
    else
      flash[:error] = "Operation not allowed"
      redirect_to collection_path
    end
  end
  
  member_action :remove_item, method: :get do
    begin
      dol = DigitalObjectLink.find(params[:digital_object_link_id])
    rescue
      redirect_to resource_path(params[:id]), error: "Could not find Digital Object Link #{params[:digital_object_link_id]}"
    end
    
    if can?(:destroy, dol)
      begin
        dol.delete
      rescue
        redirect_to resource_path(params[:id]), error: "Could not delete link #{params[:digital_object_link_id]}"
      end
      redirect_to resource_path(params[:id]), notice: "Link deleted successfully"
    else
      flash[:error] = "Operation not allowed"
      redirect_to collection_path
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
  
  index :as => :grid, :download_links => false do |obj|
    div do
        link_to(image_tag(obj.attachment.url(:medium)), admin_digital_object_path(obj))
    end
    a truncate(obj.description), :href => admin_digital_object_path(obj)
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
    end
    
    if ad.digital_object_links.size > 0
        panel I18n.t(:links) do
          table_for ad.digital_object_links do
            column I18n.t(:link_type), :object_link_type
            column I18n.t(:linked_object) do |dol|
                dol.description
            end	
            column "ID" do |dol|
              if dol.object_link_id
                link_to dol.object_link_id, controller: dol.object_link_type.pluralize.underscore.downcase.to_sym, action: :show, id: dol.object_link_id
              else
                "Object unattached"
              end
            end
            column "" do |dol|
              if can?(:destroy, dol)
              link_to I18n.t(:link_remove), 
                {controller: :digital_objects, action: :remove_item, id: resource.id, params: {digital_object_link_id: dol.id}}, 
                data: { confirm: I18n.t(:link_remove_confirm) }
              end
            end
          end
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
    render :partial => "activeadmin/section_sidebar_do_links", :locals => { :item => digital_object }
  end
  
  ##########
  ## Edit ##
  ##########
  
  form :html => {:multipart => true} do |f|
    f.inputs do
      f.input :description,:label => I18n.t(:filter_description)
      f.input :attachment, as: :file, :label => I18n.t(:filter_image)
      f.input :wf_owner, label: I18n.t(:record_owner), as: :select, multiple: false, include_blank: false, collection: User.sort_all_by_last_name if current_user.has_role?(:admin) || current_user.has_role?(:editor)
      f.input :lock_version, :as => :hidden
      # passing additional parameters for adding the object link directly after the creation
      #if (params[:new_object_link_type] &&  params[:new_object_link_id])
        f.input :new_object_link_type, :as => :hidden #:input_html => {:value =>  params[:new_object_link_type]}
        f.input :new_object_link_id, :as => :hidden #:input_html => {:value =>  params[:new_object_link_id]}
				#end
    end
  end

  sidebar :actions, :only => [:edit, :new, :update, :create] do
    render :partial => "activeadmin/section_sidebar_edit", :locals => { :item => digital_object }
  end
end
