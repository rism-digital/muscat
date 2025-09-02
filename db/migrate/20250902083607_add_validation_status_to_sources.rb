class AddValidationStatusToSources < ActiveRecord::Migration[7.2]
  def change
        add_column :sources, :validation_status, :integer, null: false, default: 0
  end
end
