class MakeWorkMediumtext < ActiveRecord::Migration[5.2]
  def change
    change_column :works, :marc_source, :mediumtext
  end
end
