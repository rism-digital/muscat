class UpdateTables < ActiveRecord::Migration[5.1]
    
    def self.up
      execute "ALTER TABLE liturgical_feasts CHANGE name name VARCHAR(255)  NULL  DEFAULT NULL"
      execute "ALTER TABLE standard_terms CHANGE term term VARCHAR(255)  NULL  DEFAULT NULL"
      execute "ALTER TABLE standard_titles CHANGE title title VARCHAR(255)  NULL  DEFAULT NULL"
      execute "ALTER TABLE places CHANGE name name VARCHAR(255)  NULL  DEFAULT NULL"
      execute "ALTER TABLE standard_titles AUTO_INCREMENT = 50200000"
    end
    
end

UpdateTables.up