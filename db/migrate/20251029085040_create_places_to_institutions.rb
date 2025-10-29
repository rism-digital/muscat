class CreatePlacesToInstitutions < ActiveRecord::Migration[7.2]
  def change
    create_table :places_to_institutions do |t|
      t.integer :place_id
      t.integer :institution_id
      t.string :marc_tag
      t.string :relator_code
    end
  end
end
