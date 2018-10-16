class AddUpdatedCreatedIndex < ActiveRecord::Migration[5.1]
  def change
    add_index :sources, :updated_at
    add_index :sources, :created_at
  end
end
