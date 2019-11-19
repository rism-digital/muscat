class UpdateTables < ActiveRecord::Migration[5.1]
    
    def self.up
      execute "insert into versions (item_type, item_id, event, whodunnit, object,created_at) select item_type, item_id, event, whodunnit, object,created_at FROM copy_versions"
      execute "drop table copy_versions"
      execute "ALTER TABLE standard_titles AUTO_INCREMENT = 50200000"
    end
    
end

UpdateTables.up