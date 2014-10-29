class AddPlaceToLibraries < ActiveRecord::Migration
  def change
    add_column :libraries, :place, :string
  end
end
