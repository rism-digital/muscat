class CreateWorksToInstitutions < ActiveRecord::Migration[5.1]
  def change
    create_table(:works_to_institutions, :id => false) do |t|
      t.column :work_id, :integer 
      t.column :institution_id, :integer
    end
    add_index :works_to_institutions, :work_id
    add_index :works_to_institutions, :institution_id

  end
end
