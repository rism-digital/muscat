class RenameInstitutionsInstitutions < ActiveRecord::Migration[5.2]
  def change
    rename_table :institutions_institutions, :institutions_to_institutions
  end
end
