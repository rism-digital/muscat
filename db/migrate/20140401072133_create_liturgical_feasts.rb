class CreateLiturgicalFeasts < ActiveRecord::Migration
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

    create_table :liturgical_feasts_sources, :id => false do |t|
      t.column :liturgical_feast_id, :integer
      t.column :source_id, :integer      
    end
  end

  def self.down
    drop_table :liturgical_feasts
    drop_table :liturgical_feasts_sources
  end
end
