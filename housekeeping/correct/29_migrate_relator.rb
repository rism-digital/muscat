codes700 = {
  #clb: "ctb", FIXED BY HAND
  
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
  asn: "oth",
  
  dnc: "prf",
  cnd: "prf", 
  voc: "prf",
  itr: "prf",
}

codes710 = {
  pat: "oth",
  bsl: "oth",
  otm: "oth",
  asm: "oth",
}


require 'progress_bar'
pb = ProgressBar.new(Source.all.count)

Source.find_in_batches do |batch|

  batch.each do |s|
    modified = false
    pb.increment!
    ## Do 700
    s.marc.each_by_tag("700") do |t|
      tn = t.fetch_first_by_tag("4")

      next if !(tn && tn.content)

      if codes700.keys.include? tn.content.to_sym
        # Should not!!!
        puts "was #{tn.content.to_sym}" if tn.content == "ctb" || tn.content == "clb"
        tn.content = codes700[tn.content.to_sym]
        #puts "is #{tn.content.to_sym}"
        modified  = true
      end

    end
    
    # Do 710
    s.marc.each_by_tag("710") do |t|
      tn = t.fetch_first_by_tag("4")

      next if !(tn && tn.content)

      if codes710.keys.include? tn.content.to_sym
        # Should not!!!
        puts "was #{tn.content.to_sym}" if tn.content == "scr" || tn.content == "dpt"
        tn.content = codes710[tn.content.to_sym]
        #puts "is #{tn.content.to_sym}"
        modified  = true
      end

    end
    
    s.save if modified
  end
end
