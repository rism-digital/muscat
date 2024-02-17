class CreateInstitutionToPublicationsRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions_to_publications, :marc_tag, :string
    add_column :institutions_to_publications, :relator_code, :string
  end
end
