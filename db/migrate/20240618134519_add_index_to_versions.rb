class AddIndexToVersions < ActiveRecord::Migration[7.1]
  def change
    add_index :versions, :item_id
  end
end
