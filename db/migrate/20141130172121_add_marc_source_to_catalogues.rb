class AddMarcSourceToCatalogues < ActiveRecord::Migration[4.2]
  def change
    add_column :catalogues, :marc_source, :text
  end
end
