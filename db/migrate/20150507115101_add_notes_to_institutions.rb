class AddNotesToInstitutions < ActiveRecord::Migration[4.2]
  def change
    unless column_exists? :institutions, :notes
      add_column :institutions, :notes, :text
    end
  end
end
