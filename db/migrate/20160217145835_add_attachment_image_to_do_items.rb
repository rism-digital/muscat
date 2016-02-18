class AddAttachmentImageToDoItems < ActiveRecord::Migration
  def self.up
    change_table :do_items do |t|
      t.attachment :image
    end
  end

  def self.down
    remove_attachment :do_items, :image
  end
end
