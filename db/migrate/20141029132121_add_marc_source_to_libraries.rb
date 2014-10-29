class AddMarcSourceToLibraries < ActiveRecord::Migration
  def change
    add_column :libraries, :marc_source, :text
  end
end
