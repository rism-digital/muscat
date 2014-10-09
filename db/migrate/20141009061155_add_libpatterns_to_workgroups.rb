class AddLibpatternsToWorkgroups < ActiveRecord::Migration
  def change
    add_column :workgroups, :libpatterns, :string
  end
end
