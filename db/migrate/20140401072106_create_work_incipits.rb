class CreateWorkIncipits < ActiveRecord::Migration[4.2]
  def self.up
    create_table(:work_incipits, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|
      
      t.column :work_id,                  :integer
      t.column :nr_work,                  :string
      t.column :movement,                 :string
      t.column :excerpt,                  :string
      t.column :heading,                  :string
      t.column :role,                     :string
      t.column :clef,                     :string
      t.column :instrument_voice,         :string
      t.column :key_signature,            :string
      t.column :time_signature,           :string
      t.column :general_note,             :text
      t.column :key_mode,                 :string
      t.column :validity,                 :string
      t.column :code,                     :string
      t.column :notation,                 :text
      t.column :text_incipit,             :text
      t.column :public_note,              :text
      
      t.column :incipit_digest,            :string
      t.column :incipit_human,             :string

      t.column :wf_audit,           :string, { :limit => 16, :default => "unapproved" }
      t.column :wf_stage,           :string, { :limit => 16, :default => "unpublished" }
      t.column :wf_notes,           :string
      t.column :wf_owner,           :integer, { :default => 0 }
      t.column :wf_version,         :integer, :default => 0

      t.column :src_count,          :integer, :default => 0

      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
         
  end

  def self.down
    drop_table :work_incipits
  end
end
