class ExportIncipitsJob < ProgressJob::Base
  
  OUTFILE="#{Rails.root}/tmp/incipits.csv"
  ZIPFILE="#{Rails.root}/public/incipits.zip"

  def initialize()
    super
  end

  def perform
    count = 0
    CSV.open(OUTFILE, "w", force_quotes: true) do |csv|
        Source.find_in_batches.each do |group|
            group.each do |source|
                source.marc.load_source false
                source.marc.each_by_tag("031") do |t|
                        
                    subtags = [:a, :b, :c, :g, :n, :o, :p]
                    vals = {}
                    
                    subtags.each do |st|
                        v = t.fetch_first_by_tag(st)
                        vals[st] = v && v.content ? v.content : ""
                    end
                    
                    next if vals[:p].strip == ''
    
                    #file.write("#{source.id}\t#{vals[:a]}\t#{vals[:b]}\t#{vals[:c]}\t#{vals[:g]}\t#{vals[:n]}\t#{vals[:o]}\t#{vals[:p]}\n")
                    csv << [source.id, "https://muscat.rism.info/admin/sources/#{source.id}", vals[:a], vals[:b], vals[:c], vals[:g], vals[:n], vals[:o], vals[:p] ]
    
                    count += 1
    
                    if count % 100000 == 0
                        puts "s #{source.id} c #{count}"
                    end
                end
    
                #pb.increment!
            end
        end
    
    end

    date = Date.current.to_formatted_s(:db)

    File.unlink(ZIPFILE) if File.exists?(ZIPFILE)

    Zip::File.open(ZIPFILE, Zip::File::CREATE) do |zipfile|
      zipfile.add("incipits_#{date}.csv", OUTFILE)
    end

  end
  
  
  def destroy_failed_jobs?
    false
  end
  
  def max_attempts
    1
  end
  
  def queue_name
    'export'
  end
end