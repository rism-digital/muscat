class DropInstitutionsToStandardTerms < ActiveRecord::Migration[7.0]
  def change
    drop_table :institutions_to_standard_terms
  end
end
