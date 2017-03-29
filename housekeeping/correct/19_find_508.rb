paren = 0
nonparen = 0
total = 0

Source.where("id < 404000000").find_in_batches do |batch|

	
  batch.each do |s|
		s.marc.load_source false
		cosi = []
		tag700 = []

    s.marc.each_by_tag("700") do |t2|
      tt = t2.fetch_first_by_tag("a")
			t4 = t2.fetch_first_by_tag("4")
			next if !(tt && tt.content)
			
			roles_count = t2.fetch_all_by_tag("4").count > 0 ? t2.fetch_all_by_tag("4").count : 1
			
			for a in 1..roles_count
				tag700 << tt.content
			end
			#puts "\t#{tt.content}\t#{t4.content}"
		end
		#tag700.sort!.uniq!

		next if (tag700.count + s.marc.by_tags("710").count) >= s.marc.by_tags("508").count

    s.marc.each_by_tag("508") do |t|
      tn = t.fetch_first_by_tag("a")

      next if !(tn && tn.content)
			
			# if it has no : it is not a name, we assume
			next if !tn.content.match("\\:")
			#if tag700.count > 0 || s.marc.by_tags("710").count
				cosi << tn.content
				
				if tn.content.match("\\[")
					paren += 1
				else
					nonparen += 1
				end
				total += 1
				#end
			
    end
		
#		if cosi.count > 0
#			puts s.id
#			cosi.each {|o| puts "\t#{o}"}
#		end

		next if cosi.count == 0
		
		cosi.each {|i| puts "#{s.id}\t#{i}"}
		
		tag700.each {|i| puts "\t#{i}\t700"}
		
#    s.marc.each_by_tag("700") do |t2|
#      tt = t2.fetch_first_by_tag("a")
#			t4 = t2.fetch_first_by_tag("4")
#			next if !(tt && tt.content)
#			puts "\t#{tt.content}\t#{t4.content}"
#		end
		
    s.marc.each_by_tag("710") do |t2|
      tt = t2.fetch_first_by_tag("a")
			next if !(tt && tt.content)
			puts "\t#{tt.content}\t710"
		end
		
  end
end

puts "total: #{total}, paren: #{paren}, non paren #{nonparen}"