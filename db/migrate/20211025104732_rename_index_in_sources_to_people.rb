class RenameIndexInSourcesToPeople < ActiveRecord::Migration[5.2]
  def change
    rename_index :sources_to_sources, :unique_records, :unique_sources
    rename_index :sources_to_people,  :unique_records, :unique_sources_to_people
  end
end
