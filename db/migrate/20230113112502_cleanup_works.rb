class CleanupWorks < ActiveRecord::Migration[5.2]
  def change
    execute("TRUNCATE TABLE `works_to_works`;")
  end
end
