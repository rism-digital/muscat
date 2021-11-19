class RenameRevueTitleToJournal < ActiveRecord::Migration[5.2]
  def change
    rename_column :publications, :revue_title, :journal
  end
end
