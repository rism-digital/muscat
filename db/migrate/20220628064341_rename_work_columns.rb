class RenameWorkColumns < ActiveRecord::Migration[5.2]
  def change
    execute("ALTER TABLE `works` RENAME COLUMN form TO opus;")
    execute("ALTER TABLE `works` RENAME COLUMN notes TO catalogue;")
    execute("ALTER TABLE `works` MODIFY catalogue VARCHAR(255);")
  end
end
