class CreatePermissionGroups < ActiveRecord::Migration[7.2]
  def change
    create_table :permission_groups do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true, null: false
      t.integer :owner_user_id
      t.timestamps
    end

    add_index :permission_groups, :name
    add_index :permission_groups, :owner_user_id

    create_table :permission_group_memberships do |t|
      t.integer :permission_group_id, null: false
      t.integer :user_id, null: false
      t.boolean :manager, default: false, null: false
      t.timestamps
    end

    add_index :permission_group_memberships,
              [:permission_group_id, :user_id],
              unique: true,
              name: :idx_pg_members_group_user
    add_index :permission_group_memberships, :user_id, name: :idx_pg_members_user

    create_table :permission_group_items do |t|
      t.integer :permission_group_id, null: false
      t.string :item_type, null: false
      t.integer :item_id, null: false
      t.timestamps
    end

    add_index :permission_group_items,
              [:permission_group_id, :item_type, :item_id],
              unique: true,
              name: :idx_pg_items_group_item
    add_index :permission_group_items,
              [:item_type, :item_id],
              name: :idx_pg_items_item

    create_table :permission_group_abilities do |t|
      t.integer :permission_group_id, null: false
      t.string :action, null: false
      t.timestamps
    end

    add_index :permission_group_abilities,
              [:permission_group_id, :action],
              unique: true,
              name: :idx_pg_abilities_group_action
    add_index :permission_group_abilities, :action, name: :idx_pg_abilities_action
  end
end
