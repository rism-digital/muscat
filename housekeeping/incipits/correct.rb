require 'digest/sha1'

file = ARGV[0]
commit = ARGV.count >= 1 ? ARGV[1] : ""

if commit == "-commit"
    puts
    puts "---------- COMMIT RUN MODE ----------"
    puts "Record modifications will be saved!"
    puts
    do_save = true
else
    puts
    puts "---------- DRY RUN MODE ----------"
    puts "add -commit after the file name to actually save"
    puts
    do_save = false
end

def change_or_create(tag, tag_name, subtag, value)
    return if !value || value.empty?

    if !subtag
        tag.add_at(MarcNode.new("source", tag_name, value.strip, nil), 0)
    else
        subtag.content = value.strip
    end
end

def insert_031q_note_not_duplicate(tag, note, incipit_id)
    return if !note || note.empty?

    found = false
    tag.fetch_all_by_tag("q").each do |nt|
        found = true if nt && nt.content && nt.content.strip == note.strip
    end

    if !found
        #puts "Add note #{incipit_id} #{note}"
        tag.add_at(MarcNode.new("source", "q", note, nil), 0)
    else
       # puts "Note already in record: #{incipit_id}, #{note} "
    end

end

def insert_599_note_not_duplicate(marc, text)
    return if !text || text.empty?

    marc.each_by_tag("599") do |t|
        t.fetch_all_by_tag("a").each do |tn|
            if tn && tn.content && tn.content.strip == text.strip
                #puts "Skip adding note #{text}"
                return
            end
        end
    end

    mc = MarcConfigCache.get_configuration("source")
    a599 = MarcNode.new("source", "599", "", mc.get_default_indicator("599"))
    a599.add_at(MarcNode.new("source", "a", text.strip, nil), 0 )

    marc.root.add_at(a599, marc.get_insert_position("559") )

end

@skip_id = []

def find_duplicates(file)
    incipits_ids = {}

    CSV.foreach(file) do |l|

        s_id = l[0]
        pae_a = l[2].to_s.strip
        pae_b = l[3].to_s.strip
        pae_c = l[4].to_s.strip

        next if s_id == "source_id"

        pae_nr = "#{pae_a}.#{pae_b}.#{pae_c}".strip
        if !incipits_ids.keys.include?(s_id)
            incipits_ids[s_id] = [pae_nr]
        else
            incipit_pae_nrs = incipits_ids[s_id]
            if incipit_pae_nrs.include?(pae_nr)
                puts "Duplicate entry for #{s_id} #{pae_nr}, skip"
                @skip_id << "#{s_id}-#{pae_nr}"
            end
        end
    end
end

# First find all dups
#find_duplicates(file)

CSV.foreach(file) do |l|

    s_id = l[0]
    url = l[1]
    pae_a = l[2].to_s.strip
    pae_b = l[3].to_s.strip
    pae_c = l[4].to_s.strip

    pae_a_new = l[5].to_s.strip
    pae_b_new = l[6].to_s.strip
    pae_c_new = l[7].to_s.strip

    voice = l[8].strip
    clef = l[9].strip
    key = l[10].strip
    time = l[11].strip
    pae = l[12].strip

    clef_new = l[13].strip
    key_new = l[14].strip
    time_new = l[15].strip
    pae_new = l[16].strip
    note = l[17].strip
    hash = l[18].strip
    global_note = l[19].strip rescue global_note = ""

=begin
CSV layout:
    "source_id",    0
    "url",          1
    "nr_a_bf",      2
    "nr_b_bf",      3
    "nr_c_bf",      4
    "nr_a_af",      5
    "nr_b_af",      6
    "nr_c_af",      7

    "voice",        8
    "clef_bf",      9
    "keysig_bf",    10
    "timesig_bf",   11

    "data_bf",      12

    "clef_af",      13
    "keysig_af",    14
    "timesig_af",   15
    "data_af",      16
    "text_note",    17
    "hash"          18
    "global_note"   19
=end

    next if s_id == "source_id"

    incipit_id = "#{s_id}-#{pae_a}.#{pae_b}.#{pae_c}".strip
    #if @skip_id.include?(incipit_id)
    #    puts "SKIP DUPLICATE #{incipit_id}"
    #    next
    #end

    begin
        source = Source.find(s_id)
    rescue ActiveRecord::RecordNotFound
        puts "Source #{s_id} was deleted".red
        next
    end

    subtags = [:a, :b, :c, :g, :n, :o, :p]
    vals = {}
    tags = {}

    source.marc.load_source true
    source.marc.each_by_tag("031") do |t|

        subtags.each do |st|
            v = t.fetch_first_by_tag(st)
            vals[st] = v && v.content ? v.content : nil
            tags[st] = v
        end

        sha1 = Digest::SHA1.hexdigest(t.to_s + source.id.to_s)

        if hash == sha1 #pae_a == vals[:a] && pae_b == vals[:b] && pae_c == vals[:c]
            #puts "updating #{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]}"

            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} clef was changed expecting #{clef} is #{vals[:g]}"; next ) if vals[:g] != nil && vals[:g].strip != clef.strip
            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} key was changed expecting #{key} is #{vals[:n]}"; next ) if vals[:n] != nil && vals[:n].strip != key.strip
            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} time was changed expecting #{time} is #{vals[:o]}"; next ) if vals[:o] != nil && vals[:o].strip != time.strip
            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} pae was changed expecting #{pae.green} is #{vals[:p].red}"; next ) if vals[:p] != nil && vals[:p].strip != pae.strip

            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} a was changed expecting #{pae_a} is #{vals[:a]}"; next ) if vals[:a] != nil && vals[:a].strip != pae_a.strip
            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} b was changed expecting #{pae_b} is #{vals[:b]}"; next ) if vals[:b] != nil && vals[:b].strip != pae_b.strip
            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} v was changed expecting #{pae_c} is #{vals[:c]}"; next ) if vals[:c] != nil && vals[:c].strip != pae_c.strip

            change_or_create(t, "g", tags[:g], clef_new)

            change_or_create(t, "n", tags[:n], key_new)
            #tags[:o].content = time_new.strip if !time_new.empty? || (vals[:o] && time_new.strip != vals[:o].strip)
            change_or_create(t, "o", tags[:o], time_new) if !time_new.empty? || (vals[:o] && time_new.strip != vals[:o].strip)
            #tags[:p].content = pae_new.strip if !pae_new.empty?
            change_or_create(t, "p", tags[:p], pae_new)

            # Fix the numbers
            change_or_create(t, "a", tags[:a], pae_a_new)
            change_or_create(t, "b", tags[:b], pae_b_new)
            change_or_create(t, "c", tags[:c], pae_c_new)

            insert_031q_note_not_duplicate(t, note, incipit_id)
            
            insert_599_note_not_duplicate(source.marc, global_note)

            t.sort_alphabetically
        end

    end

    source.save if do_save
end
