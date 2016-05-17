class CreateRelationshipTablesCatalogue < ActiveRecord::Migration
  def change
   
    # Catalogue -> People
    create_table(:catalogues_to_people, :id => false) do |t|
      t.column :catalogue_id, :integer 
      t.column :person_id, :integer
    end
    
    add_index :catalogues_to_people, :person_id
    add_index :catalogues_to_people, :catalogue_id
    
    # Catalogue -> Places
    create_table(:catalogues_to_places, :id => false) do |t|
      t.column :catalogue_id, :integer 
      t.column :place_id, :integer
    end
    
    add_index :catalogues_to_places, :place_id
    add_index :catalogues_to_places, :catalogue_id
    
    # Catalogue -> Institutions
    create_table(:catalogues_to_institutions, :id => false) do |t|
      t.column :catalogue_id, :integer 
      t.column :institution_id, :integer
    end
    
    add_index :catalogues_to_institutions, :institution_id
    add_index :catalogues_to_institutions, :catalogue_id
    
    # Catalogue -> Std_terms
    create_table(:catalogues_to_standard_terms, :id => false) do |t|
      t.column :catalogue_id, :integer 
      t.column :standard_term_id, :integer
    end
    
    add_index :catalogues_to_standard_terms, :standard_term_id
    add_index :catalogues_to_standard_terms, :catalogue_id
   


  end
end
