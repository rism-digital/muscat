class CreatePlacesToPublications < ActiveRecord::Migration[7.2]
  def change
    create_table :places_to_publications do |t|
      t.integer :place_id
      t.integer :publication_id
      t.string :marc_tag
      t.string :relator_code
    end
  end
end
