class AddWorkRelation < ActiveRecord::Migration[5.1]
  def change
    create_table(:works_to_liturgical_feasts, :id => false) do |t|
      t.column :work_id, :integer 
      t.column :liturgical_feast_id, :integer
    end
    add_index :works_to_liturgical_feasts, :work_id
    add_index :works_to_liturgical_feasts, :liturgical_feast_id

    create_table(:works_to_people, :id => false) do |t|
      t.column :work_id, :integer 
      t.column :person_id, :integer
    end
    add_index :works_to_people, :work_id
    add_index :works_to_people, :person_id

    create_table(:works_to_works, :id => false) do |t|
      t.column :work_a_id, :integer 
      t.column :work_b_id, :integer
    end
    add_index :works_to_works, :work_a_id
    add_index :works_to_works, :work_b_id
  
  end
end
