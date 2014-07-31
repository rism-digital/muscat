class CreateInstitutions < ActiveRecord::Migration
  def self.up
    create_table(:institutions, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|

      t.column :name,               :string, { :null => false }
      t.column :alternates,         :text
      t.column :notes,              :text
      
      t.column :wf_audit,           :string, { :limit => 16, :default => "unapproved" }
      t.column :wf_stage,           :string, { :limit => 16, :default => "unpublished" }
      t.column :wf_notes,           :string
      t.column :wf_owner,           :integer, { :default => 0 }
      t.column :wf_version,         :integer, :default => 0
      
      t.column :src_count,          :integer, :default => 0

      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime     
    end
    
    add_index :institutions, :name
    add_index :institutions, :wf_stage
    
    create_table :institutions_sources, :id => false do |t|
      t.column :institution_id, :integer
      t.column :source_id, :integer      
    end
    
    execute "ALTER TABLE institutions AUTO_INCREMENT=#{RISM::BASE_NEW_ID}"
    
  end

  def self.down
    drop_table :institutions
    drop_table :institutions_sources
  end
end
