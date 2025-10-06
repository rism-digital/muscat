class MakePublicationWorkCatalogueSmallint < ActiveRecord::Migration[7.2]
  def change
    # limit: 2 makes it a smallint
    change_column :publications, :work_catalogue, :integer, limit: 2, null: false, default: false
  end
end
