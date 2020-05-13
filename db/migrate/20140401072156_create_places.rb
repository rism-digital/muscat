class CreatePlaces < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:places, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
    
      t.column :name,               :string, { :null => false }
      t.column :country,            :string
      t.column :district,           :string
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
    
    add_index :places, :name
    add_index :places, :wf_stage
    
    create_table :places_sources, :id => false do |t|
      t.column :place_id, :integer
      t.column :source_id, :integer      
    end
    
    add_index :places_sources, :place_id
    add_index :places_sources, :source_id
    
    execute "ALTER TABLE places AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:place]}"
    
  end

  def self.down
    drop_table :places
    drop_table :places_sources
  end
end
