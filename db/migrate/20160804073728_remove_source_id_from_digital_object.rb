class RemoveSourceIdFromDigitalObject < ActiveRecord::Migration
  def change
    remove_column :digital_objects, :source_id, :integer
  end
end
