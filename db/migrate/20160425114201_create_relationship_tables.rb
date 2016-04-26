class CreateRelationshipTables < ActiveRecord::Migration
  def change
    # People -> Place
    create_table(:people_to_places, :id => false) do |t|
      t.column :place_id, :integer 
      t.column :person_id, :integer
    end
    
    add_index :people_to_places, :person_id
    add_index :people_to_places, :place_id
    
    
    
    # Institutions -> People
    create_table(:institutions_to_people, :id => false) do |t|
      t.column :institution_id, :integer 
      t.column :person_id, :integer
    end
    
    add_index :institutions_to_people, :person_id
    add_index :institutions_to_people, :institution_id
    
    # Institution -> Catalogue
    create_table(:institutions_to_catalogues, :id => false) do |t|
      t.column :catalogue_id, :integer 
      t.column :institution_id, :integer
    end
    
    add_index :institutions_to_catalogues, :institution_id
    add_index :institutions_to_catalogues, :catalogue_id
    
    # Institution -> Place
    create_table(:institutions_to_places, :id => false) do |t|
      t.column :place_id, :integer 
      t.column :institution_id, :integer
    end
    
    add_index :institutions_to_places, :institution_id
    add_index :institutions_to_places, :place_id
    
    # Institutions -> standard term
    create_table(:institutions_to_standard_terms, :id => false) do |t|
      t.column :standard_term_id, :integer 
      t.column :institution_id, :integer
    end
    
    add_index :institutions_to_standard_terms, :institution_id
    add_index :institutions_to_standard_terms, :standard_term_id
    
    
    
    # Catalogue -> People
    create_table(:catalogues_to_people, :id => false) do |t|
      t.column :catalogue_id, :integer 
      t.column :person_id, :integer
    end
    
    add_index :catalogues_to_people, :person_id
    add_index :catalogues_to_people, :catalogue_id
    
    # Catalogue -> Institution
    create_table(:catalogues_to_institutions, :id => false) do |t|
      t.column :catalogue_id, :integer 
      t.column :institution_id, :integer
    end
    
    add_index :catalogues_to_institutions, :institution_id
    add_index :catalogues_to_institutions, :catalogue_id
    
    # Catalogue -> Place
    create_table(:catalogues_to_places, :id => false) do |t|
      t.column :place_id, :integer 
      t.column :catalogue_id, :integer
    end
    
    add_index :catalogues_to_places, :catalogue_id
    add_index :catalogues_to_places, :place_id
    
    # Institutions -> standard term
    create_table(:catalogues_to_standard_terms, :id => false) do |t|
      t.column :standard_term_id, :integer 
      t.column :catalogue_id, :integer
    end
    
    add_index :catalogues_to_standard_terms, :catalogue_id
    add_index :catalogues_to_standard_terms, :standard_term_id
    
  end
end