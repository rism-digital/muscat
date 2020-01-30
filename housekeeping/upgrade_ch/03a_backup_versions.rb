class UpdateTables < ActiveRecord::Migration[5.1]
    
    def self.up
      execute "create table copy_versions like versions"
      execute "insert into copy_versions select * from versions"
      execute "alter table copy_versions drop column id"
    end
    
end

UpdateTables.up