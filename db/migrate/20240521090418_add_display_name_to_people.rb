class AddDisplayNameToPeople < ActiveRecord::Migration[7.0]
  def change
    add_column :people, :display_name, :string
  end
end
