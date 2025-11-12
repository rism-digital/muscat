class RemoveTypusFromStandardTitle < ActiveRecord::Migration[7.2]
  def change
    remove_column :standard_titles, :typus, :string
  end
end
