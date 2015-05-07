class AddAlternatesToInstitutions < ActiveRecord::Migration
  def change
    add_column :institutions, :alternates, :text
  end
end
