class AddCanonicImitation < ActiveRecord::Migration[5.1]
  def self.up
    create_table(:canonic_imitations, :options => 'ENGINE=InnoDB DEFAULT CHARSET=utf8') do |t|

      t.column :interval,               :string
      t.column :interval_direction,     :string
      t.column :temporal_offset,        :string
      t.column :offset_units,           :string
      t.column :mensurations,           :string
      t.column :canonic_technique_id,   :integer

      t.column :wf_audit,               :integer, { limit: 4, :default => 0 }
      t.column :wf_stage,               :integer, { limit: 4, :default => 0 }
      t.column :wf_notes,               :string,  { limit: 255 }
      t.column :wf_owner,               :integer, { limit: 4, :default => 0 }
      t.column :wf_version,             :integer, { limit: 4, :default => 0 }

      t.column :created_at,             :datetime
      t.column :updated_at,             :datetime

      t.column :lock_version,           :integer, { limit: 4, :default => 0, :null => false }
    end

    add_index :canonic_imitations, :interval
    add_index :canonic_imitations, :interval_direction
    add_index :canonic_imitations, :temporal_offset
    add_index :canonic_imitations, :offset_units
    add_index :canonic_imitations, :wf_stage

    # execute "ALTER TABLE institutions AUTO_INCREMENT=#{RISM::BASE_NEW_IDS[:canonic_imitations]}"

  end

  def self.down
    drop_table :canonic_imitations
  end
end