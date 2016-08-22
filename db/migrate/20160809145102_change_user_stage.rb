class ChangeUserStage < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.integer :preference_wf_stage, default: 1
    end
  end
end