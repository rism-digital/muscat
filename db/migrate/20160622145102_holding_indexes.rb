class HoldingIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :holdings, :source_id
  end
end