class CreateWorksToInstitutionsRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :works_to_institutions, :marc_tag, :string
    add_column :works_to_institutions, :relator_code, :string
  end
end

