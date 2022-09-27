class AddEmailToWorkgroups < ActiveRecord::Migration[5.2]
  def change
    add_column :workgroups, :email, :string
    add_index :workgroups, :email, unique: true
  end
end
