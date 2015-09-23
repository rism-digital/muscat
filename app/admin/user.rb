ActiveAdmin.register User do
  menu :parent => "admin_menu", :label => proc {I18n.t(:menu_users)}, :if => proc{ can? :manage, User }
  
  permit_params :email, :password, :password_confirmation, :name, workgroup_ids: [], role_ids: []

  controller do
    def update
      if params[:user][:password].blank?
        params[:user].delete("password")
        params[:user].delete("password_confirmation")
      end
    super
    end
  end

  ###########
  ## Index ##
  ###########

  filter :name
  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  index :download_links => false do
    selectable_column
    id_column
    column :name
    column :email
    column I18n.t(:workgroups) do |user|
         user.get_workgroups.join(", ")
    end
    column I18n.t(:roles) do |user|
         user.get_roles.join(", ")
    end
    #column :institutions
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  ##########
  ## Show ##
  ##########

  show do
    attributes_table do
      row :name
      row :email
      row I18n.t(:workgroups) do |n|
             user.workgroups.map(&:name).join(", ").html_safe
      end
      row I18n.t(:roles) do |user|
           user.get_roles.join(", ")
      end
      row :sign_in_count
      row :created_at
      row :updated_at
    end
  end
  
  ##########
  ## Edit ##
  ##########

  form do |f|
    f.inputs I18n.t(:user_details) do
      f.input :name
      f.input :email

      if can? :update, User
        f.input :password
        f.input :password_confirmation
      end
      if can? :manage, User
        f.input :workgroups, as: :select, multiple: true, collection: Workgroup.all 
        f.input :roles, as: :select, multiple: false, collection: Role.all
      end
    end
  end
  
  sidebar :actions, :only => [:edit, :new] do
    render("editor/section_sidebar_save") # Calls a partial
  end

end
