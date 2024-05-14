class DeleteTitledFullnamedFromPeople < ActiveRecord::Migration[7.0]
  def change
    remove_column :people, :full_name_d
  end
end
