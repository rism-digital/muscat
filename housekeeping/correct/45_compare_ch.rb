require 'net/http'

puts "Loading new ids"
new_person_ids = {}
CSV.foreach("housekeeping/upgrade_ch/people_newids.csv") do |r|
    new_person_ids[r[1]] = r[0]
end
#ap new_person_ids
puts "done"

URL = "http://dev.muscat-project.org/catalog/"

check_added = false

pb = ProgressBar.new(30000)

Source.limit(30000).each do |orig_source|
    pb.increment!
    m = Net::HTTP.get(URI(URL + "#{orig_source.id}.txt"))

    marc = MarcSource.new(m)
    marc.load_source(false)

    first = []
    second = []

    marc.each_by_tag("700") do |t|
        first << t#.to_s.force_encoding("UTF-8").gsub("=", "").to_s.strip
    end

    orig_source.marc.each_by_tag("700") do |t|
        second << t#.to_s.force_encoding("UTF-8").gsub("=", "").to_s.strip
    end

    next if first.empty? || second.empty?

    #next if first.count == 1 && second.count == 1 


    if first.count < second.count
        found = false
        newids = []
        first.each do |first_tag|
            
            first_a = ""
            st = first_tag.fetch_first_by_tag("a")
            if st && st.content
              first_a = st.content.force_encoding("UTF-8")
            end

            
            st = first_tag.fetch_first_by_tag("0")
            if st && st.content
                newids << st.content
            end
    
            second.each do |second_tag|
                second_a = ""
                st = second_tag.fetch_first_by_tag("a")
                if st && st.content
                    second_a = st.content.force_encoding("UTF-8")
                end
                found = true if first_a == second_a
            end
    
            
        end
        puts "#{orig_source.id}\t#{first.to_s.green}\t#{second.to_s.red}" if !found && !new_person_ids.include?(newids)
    end

    if check_added == true
        next if !second.empty?
    end

    #puts "#{orig_source.id}\t#{first.to_s.green}\t#{second.to_s.red}" if first.count < second.count
end

=begin

=end