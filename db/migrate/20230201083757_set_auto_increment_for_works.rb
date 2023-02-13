class SetAutoIncrementForWorks < ActiveRecord::Migration[5.2]
  def change
    execute "ALTER TABLE works AUTO_INCREMENT=5000"
  end
end
