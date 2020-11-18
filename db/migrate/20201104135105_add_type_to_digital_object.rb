class AddTypeToDigitalObject < ActiveRecord::Migration[5.2]
  def change
    add_column :digital_objects, :attachment_type, :integer, default: 0
  end
end
