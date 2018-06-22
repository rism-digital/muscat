class CreateInstitutionsUsers < ActiveRecord::Migration[4.2]
  def change
    create_table :institutions_users, id: false, force: true do |t|
    t.integer "user_id"
    t.integer "institution_id"
  end

  add_index "institutions_users", ["institution_id"], name: "index_institutions_users_on_institution_id", using: :btree
  add_index "institutions_users", ["user_id"], name: "index_institutions_users_on_user_id", using: :btree


    
    
    
  end
end
