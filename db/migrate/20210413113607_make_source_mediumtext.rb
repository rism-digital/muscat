class MakeSourceMediumtext < ActiveRecord::Migration[5.2]
  def change
    change_column :sources, :marc_source, :mediumtext
  end
end
