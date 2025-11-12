class RemoveWorkIncipit < ActiveRecord::Migration[7.2]
  def change
    drop_table :work_incipits
  end
end
