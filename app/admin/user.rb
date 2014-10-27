ActiveAdmin.register User do

  menu :parent => "Administration", url: ->{ users_path(locale: I18n.locale) }
  
  permit_params :email, :password, :password_confirmation, :name, :workgroup, role_ids: []
  
  index do
    selectable_column
    id_column
    column :name
    column :email
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
    f.inputs "User Details" do
      f.input :name
      f.input :email
      f.input :workgroup
      f.input :password
      f.input :password_confirmation
      f.input :roles, as: :check_boxes, multiple: true, collection: Role.all
    end
    f.actions
  end

end
