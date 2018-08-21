class AddUserOptions < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :notifications, :text
    add_column :users, :notification_type, :integer
  end
end
