class AddMoreIndexToVersions < ActiveRecord::Migration[7.2]
  def change
    add_index :versions, [:event, :item_type]
  end
end
