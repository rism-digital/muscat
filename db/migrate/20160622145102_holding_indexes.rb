class HoldingIndexes < ActiveRecord::Migration
  def change
    add_index :holdings, :source_id
  end
end