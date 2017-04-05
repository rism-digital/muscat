require 'progress_bar'

versions = PaperTrail::Version.all

pb = ProgressBar.new(versions.count)

versions.each do |v|
	
  #  execute("UPDATE #{model.to_s} SET wf_stage = 1 where wf_stage = 'published' ")
  #  execute("UPDATE #{model.to_s} SET wf_stage = 0 where wf_stage = 'unpublished' ")
  #  execute("UPDATE #{model.to_s} SET wf_stage = 2 where wf_stage = 'deleted' ")

  object = YAML::load(v.object)
  
  if object.has_key?("wf_stage")
    if object["wf_stage"] == "published"
      object["wf_stage"] = 1
    elsif object["wf_stage"] == "unpublished"
      object["wf_stage"] = 0
    elsif object["wf_stage"] == "deleted"
      object["wf_stage"] = 2
    else
      puts "Unknown wf_stage #{object["wf_stage"]} #{object["id"]}"
      object["wf_stage"] = 0
    end
  end
  
  object["wf_audit"] = 0 if object.has_key?("wf_audit")

  v.object = object.to_yaml

  v.save

  pb.increment!
end