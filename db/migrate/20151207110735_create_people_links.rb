class CreatePeopleLinks < ActiveRecord::Migration[4.2]

  def self.up
    
    create_table :people_to_people, :id => false do |t|
      t.column :person_a_id, :integer
      t.column :person_b_id, :integer      
    end
    
    add_index :people_to_people, :person_a_id
    add_index :people_to_people, :person_b_id
    
    
    create_table :institutions_people, :id => false do |t|
      t.column :institution_id, :integer
      t.column :person_id, :integer      
    end
    
    add_index :institutions_people, :institution_id
    add_index :institutions_people, :person_id
    
  end

  def self.down
    drop_table :people_to_people
    drop_table :institutions_people
  end

end
