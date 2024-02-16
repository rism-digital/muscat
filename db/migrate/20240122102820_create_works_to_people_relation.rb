class CreateWorksToPeopleRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :works_to_people, :marc_tag, :string
    add_column :works_to_people, :relator_code, :string
  end
end

