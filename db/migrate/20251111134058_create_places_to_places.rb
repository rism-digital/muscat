class CreatePlacesToPlaces < ActiveRecord::Migration[7.2]
  def change
    create_table :places_to_places do |t|
      t.column :place_a_id, :integer
      t.column :place_b_id, :integer    
      t.column :marc_tag, :string
      t.column :relator_code, :string
    end
  end
end
