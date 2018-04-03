class AddMarcSourceToInstitutions < ActiveRecord::Migration[4.2]
  def change
    add_column :institutions, :marc_source, :text
  end
end
