class RenameDescriptionToTitleInPublications < ActiveRecord::Migration[5.2]
  def change
    rename_column :publications, :description, :title
  end
end
