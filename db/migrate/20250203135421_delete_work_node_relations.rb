class DeleteWorkNodeRelations < ActiveRecord::Migration[7.2]
  def change
    drop_table :work_nodes_to_institutions
    drop_table :work_nodes_to_liturgical_feasts
    drop_table :work_nodes_to_publications
    drop_table :work_nodes_to_standard_terms
    drop_table :work_nodes_to_standard_titles
  end
end
