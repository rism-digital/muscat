class AddIndexToWorks < ActiveRecord::Migration[5.2]
  def change
    add_index :works, :person_id
    add_index :works, :catalogue
    add_index :works, :opus
    add_index :works, :created_at
    add_index :works, :updated_at
  end
end
