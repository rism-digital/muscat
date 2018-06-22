class CreateStandardTerms < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:standard_terms,:options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
    
      t.column :term,               :string, :null => false
      t.column :alternate_terms,    :text
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
    
    create_table :sources_standard_terms, :id => false do |t|
      t.column :standard_term_id, :integer
      t.column :source_id, :integer      
    end
    
    add_index :standard_terms, :term
    add_index :standard_terms, :wf_stage
    
    add_index :sources_standard_terms, :standard_term_id
    add_index :sources_standard_terms, :source_id
    
    execute "ALTER TABLE standard_terms AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:standard_term]}"
    
  end

  def self.down
    drop_table :standard_terms
    drop_table :sources_standard_terms
  end
end
