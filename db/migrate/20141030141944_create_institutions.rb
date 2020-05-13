class CreateInstitutions < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:institutions, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
          
      t.column :siglum,             :string, { :limit => 32 }
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
    
    add_index :institutions, :siglum
    add_index :institutions, :wf_stage
    
    create_table(:institutions_sources, :id => false) do |t|
      t.column :institution_id, :integer
      t.column :source_id, :integer      
    end
    
    add_index :institutions_sources, :institution_id
    add_index :institutions_sources, :source_id
    
    execute "ALTER TABLE institutions AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:institution]}"
    
  end

  def self.down
    drop_table :institutions
    drop_table :institutions_sources
  end
end
