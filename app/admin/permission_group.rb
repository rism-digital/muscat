ActiveAdmin.register PermissionGroup do
  menu :parent => "admin_menu", :label => "Permission Groups", :if => proc { can? :read, PermissionGroup }

  permit_params :name,
                :description,
                :active,
                :owner_user_id,
                user_ids: [],
                action_names: [],
                permission_group_items_attributes: [:id, :item_type, :item_id, :_destroy]

  controller do
    before_create do |permission_group|
      permission_group.owner_user ||= current_user
    end
  end

  filter :name
  filter :active
  filter :owner_user
  filter :users_id_in,
         as: :select,
         label: "Users",
         collection: -> { User.sort_all_by_last_name.map { |user| [user.name, user.id] } }
  filter :created_at
  filter :updated_at

  index download_links: false do
    selectable_column
    id_column
    column :name
    column :active
    column :owner_user
    column "Users" do |permission_group|
      permission_group.users.map(&:name).join(", ")
    end
    column "Abilities" do |permission_group|
      permission_group.action_labels.join(", ")
    end
    column "Items" do |permission_group|
      permission_group.permission_group_items.count
    end
    actions
  end

  show do
    attributes_table do
      row :name
      row :description
      row :active
      row :owner_user
      row "Users" do |permission_group|
        permission_group.users.map(&:name).join(", ")
      end
      row "Abilities" do |permission_group|
        permission_group.action_labels.join(", ")
      end
      row :created_at
      row :updated_at
    end

    panel "Items" do
      table_for permission_group.permission_group_items.includes(:item) do
        column :item_type
        column :item_id
        column "Item" do |permission_group_item|
          permission_group_item.item_label
        end
      end
    end
  end

  form do |f|
    f.inputs "Permission Group" do
      f.input :name
      f.input :description
      f.input :active
      f.input :users,
              as: :select,
              multiple: true,
              collection: User.sort_all_by_last_name.map { |user| [user.name, user.id] }
      f.input :action_names,
              as: :check_boxes,
              collection: PermissionGroup::AVAILABLE_ACTIONS.map { |action| [PermissionGroup.action_label(action), action] }
    end

    f.inputs "Items" do
      f.has_many :permission_group_items, allow_destroy: true, new_record: "Add item" do |item_form|
        item_form.input :item_type, as: :select, collection: PermissionGroup::ITEM_TYPES
        item_form.input :item_id
      end
    end

    f.actions
  end
end
