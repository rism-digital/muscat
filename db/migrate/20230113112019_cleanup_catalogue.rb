class CleanupCatalogue < ActiveRecord::Migration[5.2]
  def change
    drop_table(:holdings_to_catalogues, if_exists: true)
    drop_table(:institutions_to_catalogues, if_exists: true)
    drop_table(:people_to_catalogues, if_exists: true)
    drop_table(:sources_to_catalogues, if_exists: true)
    drop_table(:work_nodes_to_catalogues, if_exists: true)
    drop_table(:works_to_catalogues, if_exists: true)
  end
end
