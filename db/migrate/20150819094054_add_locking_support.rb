class AddLockingSupport < ActiveRecord::Migration[4.2]
  def change    
    unless column_exists? :people, :lock_version
      add_column :people, :lock_version, :integer, { :default => 0, :null => false }
    end
  end
end
