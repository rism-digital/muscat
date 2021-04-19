class DropCataloguesCatalogues < ActiveRecord::Migration[5.2]
  def change
    drop_table :catalogues_catalogues
  end
end
