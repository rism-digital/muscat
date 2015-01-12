class AddMarcSourceToInstitutions < ActiveRecord::Migration
  def change
    add_column :institutions, :marc_source, :text
  end
end
