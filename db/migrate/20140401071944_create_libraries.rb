class CreateLibraries < ActiveRecord::Migration
  def self.up
    create_table(:libraries, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
          
      t.column :siglum,             :string, { :limit => 32, :null => false }
      t.column :name,               :string
      t.column :address,            :string
      t.column :url,                :string
      t.column :phone,              :string
      t.column :email,              :string
      
      t.column :wf_audit,           :string, { :limit => 16, :default => "unapproved" }
      t.column :wf_stage,           :string, { :limit => 16, :default => "unpublished" }
      t.column :wf_notes,           :string
      t.column :wf_owner,           :integer, { :default => 0 }
      t.column :wf_version,         :integer, :default => 0
      
      t.column :src_count,          :integer, :default => 0

      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime  
    end
    
    add_index :libraries, :siglum
    add_index :libraries, :wf_stage
    
    create_table(:libraries_sources, :id => false) do |t|
      t.column :library_id, :integer
      t.column :source_id, :integer      
    end
    
    execute "ALTER TABLE libraries AUTO_INCREMENT=#{RISM::BASE_NEW_ID}"
    
  end

  def self.down
    drop_table :libraries
    drop_table :libraries_sources
  end
end