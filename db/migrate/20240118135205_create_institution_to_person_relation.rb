class CreateInstitutionToPersonRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions_to_people, :marc_tag, :string
    add_column :institutions_to_people, :relator_code, :string
  end
end
