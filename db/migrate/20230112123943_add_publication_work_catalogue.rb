class AddPublicationWorkCatalogue < ActiveRecord::Migration[5.2]
  def change
    add_column :publications, :work_catalogue, :boolean, :default => false, :null => false
  end
end
