class AddTgnIdToPlaces < ActiveRecord::Migration[7.2]
  def change
    add_column :places, :tgn_id, :string
  end
end
