class RemoveUniqueEmailFromWorkgroups < ActiveRecord::Migration[5.2]
  def change
    remove_index :workgroups, :email 
    add_index :workgroups, :email # Not unique anymore
  end
end
