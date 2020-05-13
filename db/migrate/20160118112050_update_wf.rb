class UpdateWf < ActiveRecord::Migration[4.2]

  def self.up
    
    [:sources, :catalogues, :people, :standard_terms, :standard_titles, :works, :work_incipits, :liturgical_feasts, :places, :institutions].each do |model|
      execute("UPDATE #{model.to_s} SET wf_stage = 1 where wf_stage = 'published' ")
      execute("UPDATE #{model.to_s} SET wf_stage = 0 where wf_stage = 'unpublished' ")
      execute("UPDATE #{model.to_s} SET wf_stage = 2 where wf_stage = 'deleted' ")
      execute("UPDATE #{model.to_s} SET wf_audit = 0 ")
    
      change_table model do |t|
        t.change :wf_stage, :integer, { :default => 0 }
        t.change :wf_audit, :integer, { :default => 0 }
      end
    end
    
  end

  def self.down

    [:sources, :catalogues, :people, :standard_terms, :standard_titles, :works, :work_incipits, :liturgical_feasts, :places, :institutions].each do |model|
      
      change_table model do |t|
        t.change :wf_audit,           :string, { :limit => 16, :default => "unapproved" }
        t.change :wf_stage,           :string, { :limit => 16, :default => "unpublished" }
      end
    
      execute("UPDATE #{model.to_s} SET wf_stage = 'deleted' where wf_stage = '2' ")
      execute("UPDATE #{model.to_s} SET wf_stage = 'published' where wf_stage = '1' ")
      execute("UPDATE #{model.to_s} SET wf_stage = 'unpublished' where wf_stage = '0' ")
      execute("UPDATE #{model.to_s} SET wf_audit = 'approved' ")
    end
    
  end

end
