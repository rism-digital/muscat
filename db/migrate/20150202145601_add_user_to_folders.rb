class AddUserToFolders < ActiveRecord::Migration
  def change
    
    change_table :folders do |t|
      t.integer :wf_owner
    end
    
  end
end
