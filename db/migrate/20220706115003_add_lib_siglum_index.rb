class AddLibSiglumIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :sources, :lib_siglum
    add_index :holdings, :lib_siglum
  end
end
