class AddCommentsToInstitutions < ActiveRecord::Migration[4.2]
  def change
    add_column :institutions, :comments, :text
  end
end
