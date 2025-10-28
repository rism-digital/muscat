class AddMarcSourceToPlaces < ActiveRecord::Migration[7.2]
  def change
    add_column :places, :marc_source, :text
    remove_column :places, :viaf, :string
    remove_column :places, :gnd, :string
    remove_column :places, :topic, :text
    remove_column :places, :sub_topic, :text
  end
end
