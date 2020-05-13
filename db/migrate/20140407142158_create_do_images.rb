class CreateDoImages < ActiveRecord::Migration[4.2]
  def change
    create_table :do_images do |t|
      t.string :file_name
      t.string :page_name
      t.string :label
      t.text :notes
      t.integer :width
      t.integer :height
      t.text :exif
      t.text :software
      t.string :orientation
      t.integer :res_number
      t.integer :tile_width
      t.integer :tile_height
      t.string :file_type

      t.timestamps
    end
    add_index :do_images, :file_type
  end
end
