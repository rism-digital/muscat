class CreateInstitutionsLibraries < ActiveRecord::Migration
  def change
    create_table :institutions_libraries, id:false, force:true do |t|
      t.integer "institution_id"
      t.integer "library_id"
    end
  add_index "institutions_libraries", ["institution_id"], name: "index_institutions_libraries_on_institution_id", using: :btree
  add_index "institutions_libraries", ["library_id"], name: "index_institutions_libraries_on_library_id", using: :btree
  end
end
