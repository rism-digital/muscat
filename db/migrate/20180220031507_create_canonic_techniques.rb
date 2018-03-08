class CreateCanonicTechniques < ActiveRecord::Migration
  def self.up
    create_table(:canonic_techniques, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|

      t.column :canon_type,             :string
      t.column :relation_operator,      :string
      t.column :relation_numerator,     :string
      t.column :relation_denominator,   :string
      t.column :interval,               :string
      t.column :interval_direction,     :string
      t.column :temporal_offset,        :string
      t.column :offset_units,           :string
      t.column :mensurations,           :string

      t.column :wf_audit,               :integer, { limit: 4, :default => 0 }
      t.column :wf_stage,               :integer, { limit: 4, :default => 0 }
      t.column :wf_notes,               :string,  { limit: 255 }
      t.column :wf_owner,               :integer, { limit: 4, :default => 0 }
      t.column :wf_version,             :integer, { limit: 4, :default => 0 }

      t.column :created_at,             :datetime
      t.column :updated_at,             :datetime

      t.column :lock_version,           :integer, { limit: 4, :default => 0, :null => false }
    end

    add_index :canonic_techniques, :canon_type
    add_index :canonic_techniques, :interval
    add_index :canonic_techniques, :interval_direction
    add_index :canonic_techniques, :temporal_offset
    add_index :canonic_techniques, :offset_units
    add_index :canonic_techniques, :wf_stage

    create_table(:sources_to_canonic_techniques, :id => false) do |t|
      t.column :canonic_technique_id, :integer
      t.column :source_id, :integer
    end

    add_index :sources_to_canonic_techniques, :canonic_technique_id
    add_index :sources_to_canonic_techniques, :source_id

    execute "ALTER TABLE institutions AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:canonic_techniques]}"

  end

  def self.down
    drop_table :canonic_techniques
    drop_table :sources_to_canonic_techniques
  end
end