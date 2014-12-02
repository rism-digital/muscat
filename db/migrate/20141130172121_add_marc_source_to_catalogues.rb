class AddMarcSourceToCatalogues < ActiveRecord::Migration
  def change
    add_column :catalogues, :marc_source, :text
  end
end
