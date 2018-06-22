class CreateWorkgroups < ActiveRecord::Migration[4.2]
  def change
    create_table :workgroups do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
  end
end
