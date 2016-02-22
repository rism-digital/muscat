class AddAttachmentAttachmentToDigitalObjects < ActiveRecord::Migration
  def self.up
    change_table :digital_objects do |t|
      t.attachment :attachment
    end
  end

  def self.down
    remove_attachment :digital_objects, :attachment
  end
end
