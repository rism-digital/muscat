class DropOldCataloguesTable < ActiveRecord::Migration[5.2]
  def change
    drop_table(:catalogues_catalogues, if_exists: true)
    drop_table(:catalogues_to_catalogues, if_exists: true)
    drop_table(:catalogues_to_institutions, if_exists: true)
    drop_table(:catalogues_to_people, if_exists: true)
    drop_table(:catalogues_to_places, if_exists: true)
    drop_table(:catalogues_to_standard_terms, if_exists: true)
    drop_table(:catalogues, if_exists: true)
  end
end
