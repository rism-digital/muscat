require 'progress_bar'
pb = ProgressBar.new(Source.all.count)

codes = {}
Source.find_in_batches do |batch|

	batch.each do |s|
		pb.increment!
		s.marc.each_by_tag("700") do |t|
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

ap codes