class CreateSourcesToStandardTitlesRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :sources_to_standard_titles, :marc_tag, :string
    add_column :sources_to_standard_titles, :relator_code, :string
  end
end
