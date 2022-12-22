class ExtendSourcesToInstitutions < ActiveRecord::Migration[5.2]
  def change
    add_column :sources_to_institutions, :marc_tag, :string
    add_column :sources_to_institutions, :relator_code, :string
  end
end
