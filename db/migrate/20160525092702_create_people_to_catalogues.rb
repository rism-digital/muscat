class CreatePeopleToCatalogues < ActiveRecord::Migration[4.2]
  def change
    # People -> Place
    create_table(:people_to_catalogues, :id => false) do |t|
      t.column :person_id, :integer 
      t.column :catalogue_id, :integer
    end
    
    add_index :people_to_catalogues, :person_id
    add_index :people_to_catalogues, :catalogue_id
  end
end