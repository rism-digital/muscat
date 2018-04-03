class CreateDoItems < ActiveRecord::Migration[4.2]
  def change
    create_table :do_items do |t|
      t.string :item_id
      t.string :title
      t.string :item_type

      t.timestamps
    end
    add_index :do_items, :item_id
    add_index :do_items, :item_type
  end
end
