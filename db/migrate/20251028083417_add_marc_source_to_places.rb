class AddMarcSourceToPlaces < ActiveRecord::Migration[7.2]
  def change
        add_column :places, :marc_source, :text
  end
end
