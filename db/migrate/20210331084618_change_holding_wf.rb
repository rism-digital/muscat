class ChangeHoldingWf < ActiveRecord::Migration[5.2]
  def self.up
    execute("update `holdings` SET wf_stage = 0 where wf_stage = 'inprogress'")
    execute("update `holdings` SET wf_stage = 0 where wf_stage = 'unpublished'")
    execute("update `holdings` SET wf_stage = 1 where wf_stage = 'published'")

    execute("update `holdings` SET wf_audit = 0")

    execute("ALTER TABLE `holdings` MODIFY COLUMN `wf_stage` INT;")
    execute("ALTER TABLE `holdings` MODIFY COLUMN `wf_audit` INT;")
  end

  def self.down
    execute("ALTER TABLE `holdings` MODIFY COLUMN `wf_stage` VARCHAR(255);")
    execute("ALTER TABLE `holdings` MODIFY COLUMN `wf_audit` VARCHAR(255);")

    execute("update `holdings` SET wf_stage = 'inprogress' where wf_stage = '0'")
    execute("update `holdings` SET wf_stage = 'published' where wf_stage = '1'")

    execute("update `holdings` SET wf_audit = 'full'")
  end
end
