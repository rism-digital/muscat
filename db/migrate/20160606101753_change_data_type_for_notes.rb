class ChangeDataTypeForNotes < ActiveRecord::Migration
  def self.up
    change_column :liturgical_feasts, :notes, :text
    change_column :places, :notes, :text
  end

  def self.down
    change_column :liturgical_feasts, :notes, :string
    change_column :places, :notes, :string
  end
end
