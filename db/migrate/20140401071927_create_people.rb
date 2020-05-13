class CreatePeople < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:people, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
      
      t.column :full_name,          :string, { :limit => 128, :null => false }
      t.column :full_name_d,        :string, { :limit => 128 }
      t.column :life_dates,         :string, :limit => 24
    
      t.column :birth_place,        :string, :limit => 128
      t.column :gender,             :tinyint, :default => 0
      t.column :composer,           :tinyint, :default => 0
      t.column :source,             :string
      t.column :alternate_names,    :text
      t.column :alternate_dates,    :text
      t.column :comments,           :text
      t.column :marc_source,        :text
      
      t.column :wf_audit,           :string, { :limit => 16, :default => "unapproved" }
      t.column :wf_stage,           :string, { :limit => 16, :default => "unpublished" }
      t.column :wf_notes,           :string
      t.column :wf_owner,           :integer, { :default => 0 }
      t.column :wf_version,         :integer, :default => 0
     
      t.column :src_count,          :integer, :default => 0

      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime  
    end   
    
    add_index :people, :full_name
    add_index :people, :wf_stage
      
    create_table(:people_sources, :id => false) do |t|
      t.column :person_id, :integer
      t.column :source_id, :integer 
    end
    
    add_index :people_sources, :person_id
    add_index :people_sources, :source_id
    
    execute "ALTER TABLE people AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:person]}"
    
  end

  def self.down
    drop_table :people
    drop_table :people_sources
  end
end
