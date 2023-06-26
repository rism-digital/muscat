class ChangeSiglumCollations < ActiveRecord::Migration[5.2]
  def change
    execute "alter table sources modify lib_siglum VARCHAR(32) collate utf8mb4_0900_as_cs null;"
    execute "alter table holdings modify lib_siglum VARCHAR(32) collate utf8mb4_0900_as_cs null;"
  end
end
