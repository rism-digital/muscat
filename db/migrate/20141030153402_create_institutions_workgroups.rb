class CreateInstitutionsWorkgroups < ActiveRecord::Migration[4.2]
  def change
    create_table :institutions_workgroups, id:false, force:true do |t|
      t.integer "workgroup_id"
      t.integer "institution_id"
    end
  add_index "institutions_workgroups", ["workgroup_id"], name: "index_workgroups_institutions_on_workgroup_id", using: :btree
  add_index "institutions_workgroups", ["institution_id"], name: "index_workgroups_institutions_on_institution_id", using: :btree
  end
end
