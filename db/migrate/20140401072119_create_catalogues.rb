class CreateCatalogues < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:catalogues, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
    
      t.column :name,               :string, { :null => false }
      t.column :author,             :string
      t.column :description,        :string
      t.column :revue_title,        :string
      t.column :volume,             :string
      t.column :place,              :string
      t.column :date,               :string
      t.column :pages,              :string
      
      t.column :wf_audit,           :string, { :limit => 16, :default => "unapproved" }
      t.column :wf_stage,           :string, { :limit => 16, :default => "unpublished" }
      t.column :wf_notes,           :string
      t.column :wf_owner,           :integer, { :default => 0 }
      t.column :wf_version,         :integer, :default => 0

      t.column :src_count,          :integer, :default => 0

      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime     
    end
    
    add_index :catalogues, :name
    add_index :catalogues, :wf_stage
    
    create_table :catalogues_sources, :id => false do |t|
      t.column :catalogue_id, :integer
      t.column :source_id, :integer      
    end
    
    add_index :catalogues_sources, :catalogue_id
    add_index :catalogues_sources, :source_id
    
    execute "ALTER TABLE catalogues AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:catalogue]}"
    
  end

  def self.down
    drop_table :catalogues
    drop_table :catalogues_sources
  end
end
