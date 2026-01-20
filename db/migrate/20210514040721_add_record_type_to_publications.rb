class AddRecordTypeToPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :record_type, :integer, limit: 1, default: 0
    add_index :publications, :record_type
  end
end
