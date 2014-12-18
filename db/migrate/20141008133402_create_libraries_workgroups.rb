class CreateLibrariesWorkgroups < ActiveRecord::Migration
  def change
    create_table :libraries_workgroups, id:false, force:true do |t|
      t.integer "workgroup_id"
      t.integer "library_id"
    end
  add_index "libraries_workgroups", ["workgroup_id"], name: "index_workgroups_libraries_on_workgroup_id", using: :btree
  add_index "libraries_workgroups", ["library_id"], name: "index_workgroups_libraries_on_library_id", using: :btree
  end
end
