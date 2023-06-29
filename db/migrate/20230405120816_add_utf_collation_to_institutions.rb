class AddUtfCollationToInstitutions < ActiveRecord::Migration[5.2]
  def change
    execute "ALTER TABLE institutions MODIFY siglum VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_as_cs;"
  end
end
