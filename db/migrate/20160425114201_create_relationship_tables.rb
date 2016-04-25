class CreateRelationshipTables < ActiveRecord::Migration
  def self.up

    create_table(:people_to_institutions, :id => false) do |t|
      t.column :person_id, :integer
      t.column :institution_id, :integer 
    end
    
    add_index :people_to_institutions, :person_id
    add_index :people_to_institutions, :institution_id
    
    create_table(:institutions_to_people, :id => false) do |t|
      t.column :institution_id, :integer 
      t.column :person_id, :integer
    end
    
    add_index :institutions_to_people, :person_id
    add_index :institutions_to_people, :institution_id
    
  end

  def self.down
    drop_table :people
    drop_table :people_sources
  end
end