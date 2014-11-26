ActiveAdmin.register User do
  menu :parent => "admin_menu", :label => proc {I18n.t(:menu_users)}, :if => proc{ can? :manage, User }
  
  permit_params :email, :password, :password_confirmation, :name, workgroup_ids: [], role_ids: []
  
  index do
    selectable_column
    id_column
    column :name
    column :email
    column I18n.t(:workgroups) do |user|
         user.get_workgroups.join(", ")
    end
    #column :institutions
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  filter :name
  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs I18n.t(:user_details) do
      f.input :name
      f.input :email
      if can? :manage, User
        f.input :workgroups, as: :select, multiple: true, collection: Workgroup.all 
        f.input :password
        f.input :password_confirmation
        f.input :roles, as: :check_boxes, multiple: true, collection: Role.all
      end
    end
    f.actions
  end

  show do
    attributes_table do 
      row :name
      row :email
      row I18n.t(:workgroups) do |n|
             user.workgroups.map(&:name).join(", ").html_safe
      end
      row :sign_in_count
      row :created_at
      row :updated_at
  end
  end


end
