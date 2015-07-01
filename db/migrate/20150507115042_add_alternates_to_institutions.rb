class AddAlternatesToInstitutions < ActiveRecord::Migration
  def change
    unless column_exists? :institutions, :alternates
      add_column :institutions, :alternates, :text
    end
  end
end
