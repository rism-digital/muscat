class AddWorkFeast < ActiveRecord::Migration[5.1]
  def change
    create_table(:works_to_liturgical_feasts, :id => false) do |t|
      t.column :work_id, :integer 
      t.column :liturgical_feast_id, :integer
    end
    
    add_index :works_to_liturgical_feasts, :work_id
    add_index :works_to_liturgical_feasts, :liturgical_feast_id
  end
end
