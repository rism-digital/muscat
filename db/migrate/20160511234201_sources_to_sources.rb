class SourcesToSources < ActiveRecord::Migration[4.2]
  def change
    # People -> Place
    create_table(:sources_to_sources, :id => false) do |t|
      t.column :source_a_id, :integer 
      t.column :source_b_id, :integer
    end
    
    add_index :sources_to_sources, :source_a_id
    add_index :sources_to_sources, :source_b_id
  end
end