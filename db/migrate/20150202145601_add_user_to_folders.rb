class AddUserToFolders < ActiveRecord::Migration[4.2]
  def change
    
    change_table :folders do |t|
      t.integer :wf_owner
    end
    
  end
end
