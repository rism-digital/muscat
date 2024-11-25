class AddShelfmarkToHoldings < ActiveRecord::Migration[7.1]
  def change
      add_column :holdings, :shelf_mark, :string
      add_index :holdings, :shelf_mark
  end
end
