class ChangeDefaultWfStageWithHoldings < ActiveRecord::Migration[4.2]
  def up
    change_column_default :holdings, :wf_stage, "published"
  end

  def down
    change_column_default :holdings, :wf_stage, "inprogress"
  end
end
