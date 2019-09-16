require 'net/http'

def fetch_single_subtag(marctag, subtag)
    st = marctag.fetch_first_by_tag(subtag)
    if st && st.content
      return st.content
    end
    return nil
end

def delete_single_subtag(marctag, subtag)
    st = marctag.fetch_first_by_tag(subtag)
    st.destroy_yourself if st
end

def replace_single_subtag(marctag, subtag, value)
    delete_single_subtag(marctag, subtag)
    marctag.add_at(MarcNode.new("source", "0", value, nil), 0)
    marctag.sort_alphabetically
end

def count_marc_tag(marc, tag)
    return marc.by_tags(tag).count
end

def remove_marc_tag(marc, tag)
    marc.by_tags(tag).each {|t| t.destroy_yourself}
end

puts "Loading new ids"
new_person_ids = {}
old_person_ids = {}
CSV.foreach("housekeeping/upgrade_ch/people_newids.csv") do |r|
    new_person_ids[r[1].to_i] = r[0].to_i
    old_person_ids[r[0].to_i] = r[1].to_i
end
puts "done"

URL = "http://dev.muscat-project.org/catalog/"

check_added = false

pb = ProgressBar.new(Source.count)

Source.all.each do |orig_source|
    mod = false
    pb.increment!
    #m = Net::HTTP.get(URI(URL + "#{orig_source.id}.txt"))

    #bmmarc = MarcSource.new(m)
    #bmmarc.load_source(false)

    chmarc = orig_source.marc

    #1 Match 700
    #Change the ID
    #If in BM, not CH, copy from BM
    #if BM > CH, overwrite from BM
    #if in CH not BM, keep
    #if CH > BM, cheep CH

    chmarc.each_by_tag("100") do |t|
        id = fetch_single_subtag(t, "0")
        if old_person_ids.include?(id)
            puts "replace #{id} with #{old_person_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", old_person_ids[id])
            mod = true
        end
    end

=begin
    if (count_marc_tag(bmmarc, "700") > count_marc_tag(chmarc, "700"))
        # Remove all the tags here
        if count_marc_tag(chmarc, "700") > 0
            remove_marc_tag(chmarc, "700")
        end
        # Copy over from BM
        bmmarc.each_by_tag("700") do |tag|
            chmarc.root.children.insert(chmarc.get_insert_position("700"), tag)
        end
    end
=end

    #puts orig_source.marc.to_marc if mod

    orig_source.suppress_reindex
    orig_source.suppress_update_count
    orig_source.suppress_update_77x

    orig_source.marc.import

    orig_source.save if mod
end

