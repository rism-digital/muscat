class AddPlaceToInstitutions < ActiveRecord::Migration
  def change
    add_column :institutions, :place, :string
  end
end
