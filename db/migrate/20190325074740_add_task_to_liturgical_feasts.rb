class AddTaskToLiturgicalFeasts < ActiveRecord::Migration[5.1]
  def change
    add_column :liturgical_feasts, :task, :string
  end
end
