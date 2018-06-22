class CreateDoDivFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :do_div_files do |t|
      t.integer :do_file_id
      t.integer :do_div_id
      t.integer :file_order

      t.timestamps
    end
  end
end
