class EnlargeStdtitle < ActiveRecord::Migration[4.2]
  def change

    change_table :sources do |t|
      t.change :std_title, :string, {:limit => 512}
      t.change :std_title_d, :string, {:limit => 512}
    end
    
    add_index :sources, :std_title
    add_index :sources, :std_title_d
  end
end