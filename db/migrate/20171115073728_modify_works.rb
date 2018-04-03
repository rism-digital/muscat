class ModifyWorks < ActiveRecord::Migration[4.2]
  def change
		add_column :works, :marc_source, :text
		add_column :works, :lock_version, :integer, { :default => 0, :null => false }
  end
end