class AddMarcToPeople < ActiveRecord::Migration
  def change
    add_column :people, :marc_source, :text
  end
end
