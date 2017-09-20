codes700 = {
  clb: "ctb",
  cst: "oth",
  prd: "oth",
  bnd: "oth",
  ppm: "oth",
  smp: "oth",
  com: "oth",
  chr: "oth",
  pat: "oth",
  bsl: "oth",
  dnr: "oth",
  art: "oth",
  dnc: "prf",
  cnd: "prf", 
  voc: "prf",
  itr: "prf",
}

require 'progress_bar'
pb = ProgressBar.new(Source.all.count)

Source.find_in_batches do |batch|

  batch.each do |s|
    modified = false
    pb.increment!
    s.marc.each_by_tag("700") do |t|
      tn = t.fetch_first_by_tag("4")

      next if !(tn && tn.content)

      if codes700.keys.include? tn.content.to_sym
        puts "was #{tn.content.to_sym}"
        tn.content = codes700[tn.content.to_sym]
        puts "is #{tn.content.to_sym}"
        modified  = true
      end

    end
    s.save if modified
  end
end
