require 'progress_bar'
pb = ProgressBar.new(Source.all.count)

@editor_profile = EditorConfiguration.get_default_layout Source.first

codes = {}
Source.find_in_batches do |batch|

       	batch.each do |s|
       		pb.increment!
       		s.marc.each_by_tag("710") do |t|
       			tn = t.fetch_first_by_tag("4")

       			next if !(tn && tn.content)

       			if codes.include?(tn.content)
       				codes[tn.content] += 1
       			else
       				codes[tn.content] = 1
       			end
       		end
       	end
       	#ap codes
end

codes_sorted =  codes.sort_by{|k,v| v}

codes_sorted.each do |a|
       	k = a[0]
       	c = a[1]
       	puts @editor_profile.get_label(k.to_s) + " #{k} #{c}"
end