class DeleteTitledFromStandardTitle < ActiveRecord::Migration[7.0]
  def change
    remove_column :standard_titles, :title_d
  end
end
