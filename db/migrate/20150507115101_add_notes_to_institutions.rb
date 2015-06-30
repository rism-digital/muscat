class AddNotesToInstitutions < ActiveRecord::Migration
  def change
    add_column :institutions, :notes, :text
  end
end
