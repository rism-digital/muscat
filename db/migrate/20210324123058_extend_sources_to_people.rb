class ExtendSourcesToPeople < ActiveRecord::Migration[5.2]
  def change
    add_column :sources_to_people, :marc_tag, :string
    add_column :sources_to_people, :relator_code, :string
  end
end
