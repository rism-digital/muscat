class DeleteUnusedInstitutionsInstitutions < ActiveRecord::Migration[5.2]
  def change
    drop_table :institutions_institutions, if_exists: true
  end
end
