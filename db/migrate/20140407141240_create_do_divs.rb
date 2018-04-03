class CreateDoDivs < ActiveRecord::Migration[4.2]
  def change
    create_table :do_divs do |t|
      t.integer :do_item_id
      t.string :title_string
      t.integer :subdiv_id
      t.string :subdiv_type

      t.timestamps
    end
  end
end
