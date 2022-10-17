class AddCorporateNameAndSubordiateUnitToInstitutions < ActiveRecord::Migration[5.2]
  def change
    add_column :institutions, :corporate_name, :string
    add_column :institutions, :subordinate_unit, :string
  end
end
