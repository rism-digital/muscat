class RemoveWorkgroupFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :workgroup, :string
  end
end
