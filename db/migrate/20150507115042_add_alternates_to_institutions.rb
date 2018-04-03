class AddAlternatesToInstitutions < ActiveRecord::Migration[4.2]
  def change
    unless column_exists? :institutions, :alternates
      add_column :institutions, :alternates, :text
    end
  end
end
