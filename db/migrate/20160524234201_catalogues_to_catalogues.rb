class CataloguesToCatalogues < ActiveRecord::Migration[4.2]
  def change
    # People -> Place
    create_table(:catalogues_to_catalogues, :id => false) do |t|
      t.column :catalogue_a_id, :integer 
      t.column :catalogue_b_id, :integer
    end
    
    add_index :catalogues_to_catalogues, :catalogue_a_id
    add_index :catalogues_to_catalogues, :catalogue_b_id
  end
end