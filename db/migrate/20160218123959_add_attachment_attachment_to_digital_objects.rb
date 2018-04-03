class AddAttachmentAttachmentToDigitalObjects < ActiveRecord::Migration[4.2]
  def self.up
    change_table :digital_objects do |t|
      t.attachment :attachment
    end
  end

  def self.down
    remove_attachment :digital_objects, :attachment
  end
end
