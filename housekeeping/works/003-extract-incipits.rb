require 'progress_bar'
require './housekeeping/works/functions'

#################################################################################
# extract the incipit for a work

def extract_incipits_for(item, work)

    incipits = Array.new
    avg_len = 0
    source_id = 0

    # Make sure inicpits are not added twice
    return if work.marc.has_tag?("031") 

    # Loop over source work relations
    SourceWorkRelation.where(work_id: work.id, relator_code: nil).find_all.each do |swr|
        src = swr.source
        src.marc.load_source false
        src_incipits = Array.new
        src_avg_len = 0

        # Because we can have more than one relation the source can have been selected already
        next if src.id == source_id
        
        src.marc.each_by_tag("031") do |tag|
            #puts tag
            s_031p = tag.fetch_first_by_tag("p")
            # skip incipits with no PAE
            next if !s_031p
            # skip incipits with only 3 characthers (probably only clef)
            next if s_031p.content and s_031p.content.length < 4
            src_incipits.append(tag)
            src_avg_len += s_031p.content.length
        end

        src_avg_len = src_avg_len / incipits.size if !incipits.empty?

        next if (src_incipits.size < incipits.size)
        next if (src_incipits.size == incipits.size && src_avg_len < avg_len)

        incipits = src_incipits
        source_id = src.id
        avg_len = src_avg_len
    end

    return if incipits.empty?

    incipits.each do |incipit|
        w_031 = incipit.deep_copy
        work.marc.root.add_at(w_031, work.marc.get_insert_position("031"))
        @incipit_count += 1
    end

    w_667 = MarcNode.new("work", "667", "", "##")
    w_667.add_at(MarcNode.new("work", "a", "Incipits imported from #{source_id}", nil), 0)
    work.marc.root.add_at(w_667, work.marc.get_insert_position("667"))

    @work_count += 1
    work.save
end

#################################################################################
# Main

if ARGV.length < 1
    puts "Too few arguments"
    exit
end

@incipit_count = 0
@work_count = 0

catalogue_file = ARGV[0]
catalogues = YAML.load(File.read("#{catalogue_file}.yml"))
puts catalogues

catalogues.each do |catalogue|
    process_works_for(catalogue.transform_keys(&:to_sym), "extract_incipits_for")
end

puts "Works to which an incipit add: #{@work_count}"
puts "Incipits added: #{@incipit_count}"
