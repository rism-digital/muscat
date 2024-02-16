class DropUnusedTables < ActiveRecord::Migration[7.0]
  def change
    drop_table :searches
    drop_table :institutions_users
    drop_table :bookmarks
  end
end
