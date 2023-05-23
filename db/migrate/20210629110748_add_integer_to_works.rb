class AddIntegerToWorks < ActiveRecord::Migration[5.2]
  def change
    add_column :works, :link_status, :integer
  end
end
