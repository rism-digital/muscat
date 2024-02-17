class CreateWorksToStandardTitlesRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :works_to_standard_titles, :marc_tag, :string
    add_column :works_to_standard_titles, :relator_code, :string
  end
end

