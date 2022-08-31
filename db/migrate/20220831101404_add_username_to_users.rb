class AddUsernameToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :username, :string
    add_column :users, :notification_email, :string
    add_column :users, :disabled, :boolean, null: false, default: false
    add_index :users, :username, unique: true
  end
end
