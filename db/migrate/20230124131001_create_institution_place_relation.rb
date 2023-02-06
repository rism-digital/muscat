class CreateInstitutionPlaceRelation < ActiveRecord::Migration[5.2]
  def change
    add_column :institutions_to_places, :marc_tag, :string
    add_column :institutions_to_places, :relator_code, :string
  end
end
