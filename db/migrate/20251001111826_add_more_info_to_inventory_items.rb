class AddMoreInfoToInventoryItems < ActiveRecord::Migration[7.2]
  def change
    add_column :inventory_items, :page_info, :string
  end
end
