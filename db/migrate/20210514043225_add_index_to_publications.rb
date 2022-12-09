class AddIndexToPublications < ActiveRecord::Migration[5.2]
  def change
    add_index :publications, :created_at
    add_index :publications, :updated_at
  end
end
