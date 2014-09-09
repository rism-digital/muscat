ActiveAdmin.register User do

  menu :parent => "Administration"
  permit_params :email, :password, :password_confirmation, :name, institution_ids: [], role_ids: []
  
  index do
    selectable_column
    id_column
    column :name
    column :email
    column "Workgroups" do |user|
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
    f.inputs "User Details" do
      f.input :name
      f.input :email
      f.input :institutions, as: :select, multiple: true, collection: Institution.joins(:libraries).uniq
      f.input :password
      f.input :password_confirmation
      f.input :roles, as: :check_boxes, multiple: true, collection: Role.all
    end
    f.actions
  end

end
