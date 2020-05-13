class CreateWorks < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:works, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
      
      t.column :person_id,    :integer  
      t.column :title,        :string
      t.column :form,         :string
      t.column :notes,        :text


      t.column :wf_audit,           :string, { :limit => 16, :default => "unapproved" }
      t.column :wf_stage,           :string, { :limit => 16, :default => "unpublished" }
      t.column :wf_notes,           :string
      t.column :wf_owner,           :integer, { :default => 0 }
      t.column :wf_version,         :integer, :default => 0

      t.column :src_count,          :integer, :default => 0

      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
    
    add_index :works, :title
    add_index :works, :wf_stage
    
    create_table :sources_works, :id => false do |t| # id was removed
      t.column :source_id, :integer 
      t.column :work_id, :integer      
    end
    
    add_index :sources_works, :work_id
    add_index :sources_works, :source_id
    
    execute "ALTER TABLE works AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:work]}"
    
  end

  def self.down
    drop_table :sources_works    
    drop_table :works
  end
end
