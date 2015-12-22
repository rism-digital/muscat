class CreateHoldings < ActiveRecord::Migration

  def self.up
    create_table(:holdings, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|

      t.column :lib_siglum,         :string
      t.column :marc_source,        :text

      t.column :lock_version,       :integer, { :default => 0, :null => false }
      
      # this fields are kept for now - to be decided
      t.column :wf_audit,           :string, { :limit => 16, :default => "unapproved" }
      t.column :wf_stage,           :string, { :limit => 16, :default => "unpublished" }
      t.column :wf_notes,           :string
      t.column :wf_owner,           :integer, { :default => 0 }
      t.column :wf_version,         :integer, :default => 0

      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
    
    add_index :holdings, :wf_stage
    
    create_table :holdings_institutions, :id => false do |t|
      t.column :holding_id, :integer
      t.column :institution_id, :integer
    end
    
    add_index :holdings_institutions, :holding_id
    add_index :holdings_institutions, :institution_id
    
    create_table :holdings_sources, :id => false do |t|
      t.column :holding_id, :integer
      t.column :source_id, :integer
    end
    
    add_index :holdings_sources, :holding_id
    add_index :holdings_sources, :source_id
    
    execute "ALTER TABLE holdings AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:holding]}"
    
  end

  def self.down
    drop_table :holdings
    drop_table :holdings_institutions
    drop_table :holdings_sources
  end

end
