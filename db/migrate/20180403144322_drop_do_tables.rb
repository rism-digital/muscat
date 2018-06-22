class DropDoTables < ActiveRecord::Migration[4.2]
  def change
    remove_foreign_key :do_div_files, column: :do_file_id rescue nil
    remove_foreign_key :do_div_files, column: :do_div_id rescue nil
    
    remove_foreign_key :do_divs, column: :do_item_id rescue nil
    
    remove_foreign_key :do_file_groups, column: :do_item_id rescue nil
    
    remove_foreign_key :do_files, column: :do_file_group_id rescue nil
    remove_foreign_key :do_files, column: :do_image_id rescue nil
    
    drop_table :do_items if ActiveRecord::Base.connection.table_exists? 'do_items'
    drop_table :do_div_files if ActiveRecord::Base.connection.table_exists? 'do_div_files'
    drop_table :do_divs if ActiveRecord::Base.connection.table_exists? 'do_divs'
    drop_table :do_file_groups if ActiveRecord::Base.connection.table_exists? 'do_file_groups'
    drop_table :do_images if ActiveRecord::Base.connection.table_exists? 'do_images'
    drop_table :do_files if ActiveRecord::Base.connection.table_exists? 'do_files'
  end
end
