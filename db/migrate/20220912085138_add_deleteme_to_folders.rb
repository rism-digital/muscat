class AddDeletemeToFolders < ActiveRecord::Migration[5.2]
  def change
    add_column :folders, :delete_date, :datetime
  end
end
