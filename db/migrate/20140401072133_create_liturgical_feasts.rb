class CreateLiturgicalFeasts < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:liturgical_feasts, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
    
      t.column :name,               :string, { :null => false }
      t.column :notes,              :string
      
      t.column :wf_audit,           :string, { :limit => 16, :default => "unapproved" }
      t.column :wf_stage,           :string, { :limit => 16, :default => "unpublished" }
      t.column :wf_notes,           :string
      t.column :wf_owner,           :integer, { :default => 0 }
      t.column :wf_version,         :integer, :default => 0

      t.column :src_count,          :integer, :default => 0

      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime     
    end

    add_index :liturgical_feasts, :name
    add_index :liturgical_feasts, :wf_stage

    create_table :liturgical_feasts_sources, :id => false do |t|
      t.column :liturgical_feast_id, :integer
      t.column :source_id, :integer      
    end
    
    add_index :liturgical_feasts_sources, :liturgical_feast_id
    add_index :liturgical_feasts_sources, :source_id
    
    execute "ALTER TABLE liturgical_feasts AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:liturgical_feast]}"
    
  end

  def self.down
    drop_table :liturgical_feasts
    drop_table :liturgical_feasts_sources
  end
end
