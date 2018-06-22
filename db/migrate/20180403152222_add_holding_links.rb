class AddHoldingLinks < ActiveRecord::Migration[5.1]
  def change
    create_table(:holdings_to_catalogues, :id => false) do |t|
      t.column :catalogue_id, :integer 
      t.column :holding_id, :integer
    end
    
    add_index :holdings_to_catalogues, :holding_id
    add_index :holdings_to_catalogues, :catalogue_id
		
    create_table(:holdings_to_places, :id => false) do |t|
      t.column :place_id, :integer 
      t.column :holding_id, :integer
    end
    
    add_index :holdings_to_places, :holding_id
    add_index :holdings_to_places, :place_id
		
    create_table(:holdings_to_people, :id => false) do |t|
      t.column :person_id, :integer 
      t.column :holding_id, :integer
    end
    
    add_index :holdings_to_people, :holding_id
    add_index :holdings_to_people, :person_id
  end
end
