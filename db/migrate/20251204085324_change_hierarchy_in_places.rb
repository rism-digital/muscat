class ChangeHierarchyInPlaces < ActiveRecord::Migration[7.2]
  def self.up
    change_column :places, :hierarchy, :text
  end

  def self.down
    change_column :places, :hierarchy, :json
  end
end
