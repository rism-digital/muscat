class RemoveSourceIdFromDigitalObject < ActiveRecord::Migration[4.2]
  def change
    remove_column :digital_objects, :source_id, :integer
  end
end
