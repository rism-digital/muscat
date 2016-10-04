class AddFieldsToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :alternate_terms, :text
    add_column :places, :topic, :text
    add_column :places, :sub_topic, :text
  end
end
