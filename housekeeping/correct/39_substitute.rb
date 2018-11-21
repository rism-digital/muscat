require 'progress_bar'

total = Source.find_by_sql("SELECT * FROM sources s where marc_source REGEXP '=593[^\n]*\[[.$.]]a[Pp]rint'").count
pb = ProgressBar.new(total)
PaperTrail.request.disable_model(Source)

Source.find_by_sql("SELECT * FROM sources s where marc_source REGEXP '=593[^\n]*\[[.$.]]a[Pp]rint'").each do |s|
  modified = false

  s.marc.each_by_tag("593") do |t|
    tn = t.each_by_tag("a") do |tn|
      next if !(tn && tn.content)
      if tn.content == "print"
        tn.content = "Print"
        modified = true
      end
    end
  end
  
  s.save if modified
  pb.increment!
end