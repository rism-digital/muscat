class CreateSourcesToPlacesRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :sources_to_places, :marc_tag, :string
    add_column :sources_to_places, :relator_code, :string
  end
end
