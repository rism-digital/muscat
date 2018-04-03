class CreateUsersWorkgroups < ActiveRecord::Migration[4.2]
  def change
    create_table :users_workgroups, id: false, force: true do |t|
    t.integer "user_id"
    t.integer "workgroup_id"
  end

  add_index "users_workgroups", ["workgroup_id"], name: "index_workgroups_users_on_workgroup_id", using: :btree
  add_index "users_workgroups", ["user_id"], name: "index_workgroups_users_on_user_id", using: :btree


    
    
    
  end
end
