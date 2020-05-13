class AddCollectionToHolding < ActiveRecord::Migration[5.1]
  def change
    add_column :holdings, :collection_id, :integer
    add_index :holdings, :collection_id
  end
end
