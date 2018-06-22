class CreateSources < ActiveRecord::Migration[4.2]

  def self.up
    create_table(:sources, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
      # changing to bingint/64bits needs limit to be set to 8 
      #t.column :id,                 :integer, { :limit => 4 }
      
      t.column :source_id,          :integer #, { :limit => 4 }
      t.column :record_type,        :tinyint, :default => 0

      t.column :std_title,          :string
      t.column :std_title_d,        :string

      t.column :composer,           :string
      t.column :composer_d,         :string

      t.column :title,              :string, { :limit => 256 }
      t.column :title_d,            :string, { :limit => 256 }

      t.column :shelf_mark,         :string
      t.column :language,           :string, :limit => 16
      t.column :date_from,          :integer
      t.column :date_to,            :integer
      t.column :lib_siglum,        :string
    
      t.column :marc_source,        :text

      # this fields are kept for now - to be decided
      t.column :wf_audit,           :string, { :limit => 16, :default => "unapproved" }
      t.column :wf_stage,           :string, { :limit => 16, :default => "unpublished" }
      t.column :wf_notes,           :string
      t.column :wf_owner,           :integer, { :default => 0 }
      t.column :wf_version,         :integer, :default => 0

      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime     
    end
    
    add_index :sources, :source_id
    add_index :sources, :record_type
    add_index :sources, :wf_stage
    
    execute "ALTER TABLE sources AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:source]}"
    
  end

  def self.down
    drop_table :sources
  end

end
