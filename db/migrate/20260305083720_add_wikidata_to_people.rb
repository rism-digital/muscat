class AddWikidataToPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :people, :wikidata_id, :string
  end
end
