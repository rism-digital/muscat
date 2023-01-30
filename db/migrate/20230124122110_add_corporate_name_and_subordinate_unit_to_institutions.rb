class AddCorporateNameAndSubordinateUnitToInstitutions < ActiveRecord::Migration[5.2]
  def change
    add_column :institutions, :corporate_name, :string
    add_column :institutions, :subordinate_unit, :string
    rename_column :institutions, :name, :full_name
  end
end
