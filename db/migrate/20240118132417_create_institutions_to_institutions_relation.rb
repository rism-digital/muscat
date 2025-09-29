class CreateInstitutionsToInstitutionsRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :institutions_to_institutions, :marc_tag, :string
    add_column :institutions_to_institutions, :relator_code, :string
  end
end
