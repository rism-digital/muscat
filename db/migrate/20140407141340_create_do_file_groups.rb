class CreateDoFileGroups < ActiveRecord::Migration
  def change
    create_table :do_file_groups do |t|
      t.integer :do_item_id
      t.string :title

      t.timestamps
    end
  end
end
