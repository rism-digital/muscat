class CreateWorkgroups < ActiveRecord::Migration
  def change
    create_table :workgroups do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
  end
end
