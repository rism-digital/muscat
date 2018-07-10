require 'progress_bar'


@parallel_jobs = 10
@all_src = Source.all.count
@limit = @all_src / @parallel_jobs

results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs) do |jobid|
	offset = @limit * jobid

	#pb = ProgressBar.new(@limit)
	solr = RSolr.connect :url => 'http://localhost:8982/solr/development/'

	Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
		source = Source.find(sid.id)
		source.marc.load_source false
		source.marc.each_by_tag("031") do |t|
            
			subtags = [:a, :b, :c, :g, :n, :o, :p]
			vals = {}
      
			subtags.each do |st|
				v = t.fetch_first_by_tag(st)
				vals[st] = v && v.content ? v.content : "0"
			end

			next if vals[:p] == "0"

			pae_nr = "#{vals[:a]}.#{vals[:b]}.#{vals[:c]}"
      
			s = "@start:#{pae_nr}\n";
			s = s + "@clef:#{vals[:g]}\n";
			s = s + "@keysig:#{vals[:n]}\n";
			s = s + "@key:\n";
			s = s + "@timesig:#{vals[:o]}\n";
			s = s + "@data:#{vals[:p]}\n";
			s = s + "@end:#{pae_nr}\n"
			#puts s
			solr.add(
				id: "Incipit #{source.id} #{pae_nr}",
				incipit_source_i: source.id,
				pae: s)
      
		end
		#pb.increment!
	end
end
