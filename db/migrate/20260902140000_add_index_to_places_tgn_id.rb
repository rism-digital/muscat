class AddIndexToPlacesTgnId < ActiveRecord::Migration[7.2]
  def change
    add_index :places, :tgn_id
  end
end
