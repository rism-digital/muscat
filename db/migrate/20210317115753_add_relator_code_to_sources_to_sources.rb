class AddRelatorCodeToSourcesToSources < ActiveRecord::Migration[5.2]
  def change
    add_column :sources_to_sources, :marc_tag, :string
    add_column :sources_to_sources, :relator_code, :string
  end
end
