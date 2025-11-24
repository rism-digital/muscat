class AddHierarchyToPlaces < ActiveRecord::Migration[7.2]
  def change
    add_column :places, :hierarchy, :json
  end
end
