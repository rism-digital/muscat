class CreateStandardTitles < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:standard_titles, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
    
      t.column :title,              :string, :null => false
      t.column :title_d,            :string, { :limit => 128 }
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
    
    create_table(:sources_standard_titles, :id => false) do |t|
      t.column :standard_title_id, :integer
      t.column :source_id, :integer
    end
    
    add_index :standard_titles, :title
    add_index :standard_titles, :wf_stage
    
    add_index :sources_standard_titles, :standard_title_id
    add_index :sources_standard_titles, :source_id
    
    execute "ALTER TABLE standard_titles AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:standard_title]}"
    
  end

  def self.down
    drop_table :standard_titles
    drop_table :sources_standard_titles
  end
end
