class RemoveWorkgroupFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :workgroup, :string
  end
end
