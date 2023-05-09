class RemoveCommentsFromPeople < ActiveRecord::Migration[5.2]
  def change
    remove_column :people, :comments, :string
  end
end
