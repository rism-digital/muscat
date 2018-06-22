class ChangeUserStage < ActiveRecord::Migration[4.2]
  def change
    change_table :users do |t|
      t.integer :preference_wf_stage, default: 1
    end
  end
end