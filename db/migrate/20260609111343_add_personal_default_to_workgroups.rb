class AddPersonalDefaultToWorkgroups < ActiveRecord::Migration[7.2]
  def change
    add_column :workgroups, :personal_default, :boolean, default: false, null: false
    add_reference :workgroups, :owner_user, foreign_key: { to_table: :users }, index: false, type: :integer
    add_index :workgroups, :owner_user_id, unique: true, where: "owner_user_id IS NOT NULL"
  end
end
