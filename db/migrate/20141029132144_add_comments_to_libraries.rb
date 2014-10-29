class AddCommentsToLibraries < ActiveRecord::Migration
  def change
    add_column :libraries, :comments, :text
  end
end
