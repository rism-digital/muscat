class ExtendSourcesToWorks < ActiveRecord::Migration[5.2]
  def change
    add_column :sources_to_works, :marc_tag, :string
    add_column :sources_to_works, :relator_code, :string
  end
end
