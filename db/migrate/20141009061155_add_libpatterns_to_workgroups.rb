class AddLibpatternsToWorkgroups < ActiveRecord::Migration[4.2]
  def change
    add_column :workgroups, :libpatterns, :string
  end
end
