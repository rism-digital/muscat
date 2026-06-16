class ChamngeCatalogEncondingInWorks < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      ALTER TABLE works
      MODIFY catalogue VARCHAR(255)
      CHARACTER SET utf8mb4
      COLLATE utf8mb4_0900_as_cs;
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE works
      MODIFY catalogue VARCHAR(255)
      CHARACTER SET utf8mb3
      COLLATE utf8mb3_general_ci;
    SQL
  end
end
