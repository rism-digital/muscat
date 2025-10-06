class AddSourceOrderToInventoryItems < ActiveRecord::Migration[7.2]
  def change
    add_column :inventory_items, :source_order, :integer, null: false, default: 0
  end
end
