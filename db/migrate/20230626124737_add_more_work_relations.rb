class AddMoreWorkRelations < ActiveRecord::Migration[5.2]
  create_table(:works_to_places, :id => false) do |t|
    t.column :work_id, :integer 
    t.column :place_id, :integer
  end
  add_index :works_to_places, :work_id
  add_index :works_to_places, :place_id
end
