class CreateFolders < ActiveRecord::Migration
  def change
    create_table :folders do |t|
      t.string :name
      t.string :type

      t.timestamps
    end
  end
end
