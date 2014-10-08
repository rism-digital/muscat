class CreateFolderItems < ActiveRecord::Migration
  def change
    create_table :folder_items do |t|
      t.integer :folder_id
      t.references :item, polymorphic: true
      t.timestamps
    end
  end
end
