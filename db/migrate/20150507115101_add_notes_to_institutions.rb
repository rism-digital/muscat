class AddNotesToInstitutions < ActiveRecord::Migration
  def change
    unless column_exists? :institutions, :notes
      add_column :institutions, :notes, :text
    end
  end
end
