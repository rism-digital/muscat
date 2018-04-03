class CreateDoFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :do_files do |t|
      t.integer :do_file_group_id
      t.integer :do_image_id
      t.string :title

      t.timestamps
    end
  end
end
