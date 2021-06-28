class RenameWorkColumns < ActiveRecord::Migration[5.2]
  def change
    rename_column :works, :form, :opus
    rename_column :works, :notes, :catalogue
  end
end
