class RenameNameShortName < ActiveRecord::Migration[5.2]
  def change
    rename_column :publications, :name, :short_name
  end
end
