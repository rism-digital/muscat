class AddFieldsToStandardTitles < ActiveRecord::Migration
  def change
    add_column :standard_titles, :typus, :string
    add_column :standard_titles, :variants, :text
  end
end
