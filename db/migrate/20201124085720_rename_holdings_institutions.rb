class RenameHoldingsInstitutions < ActiveRecord::Migration[5.2]
  def change
    rename_table :holdings_institutions, :holdings_to_institutions
  end
end
