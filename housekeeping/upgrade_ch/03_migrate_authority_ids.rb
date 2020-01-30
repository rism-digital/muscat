require 'net/http'

# Dump the sources table with this command:
# mysqldump -n -t --complete-insert -u rism -p muscat_development sources > mod_sources.sql

# To copy the versions:
# create table copy_versions like versions;
# insert into copy_versions select * from versions;
# alter table copy_versions drop column id;
# mysqldump --complete-insert -u rism -p muscat_development copy_versions > copy_versions.sql

# Copy to new sys
# insert into versions (item_type, item_id, event, whodunnit, object,created_at) select item_type, item_id, event, whodunnit, object,created_at FROM copy_versions;
# drop table copy_versions;

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
    marctag.add_at(MarcNode.new("source", subtag, value, nil), 0)
    marctag.sort_alphabetically
end

def count_marc_tag(marc, tag)
    return marc.by_tags(tag).count
end

def remove_marc_tag(marc, tag)
    marc.by_tags(tag).each {|t| t.destroy_yourself}
end

print "Loading new ids "
@new_person_ids = {}
@old_person_ids = {}
CSV.foreach("housekeeping/upgrade_ch/people_newids.csv") do |r|
    # format is CH id, BM id
    @new_person_ids[r[1].to_i] = r[0].to_i
    @old_person_ids[r[0].to_i] = r[1].to_i
end
print "."

@old_650_ids = {}
# Format is BM id, CH id
CSV.foreach("housekeeping/upgrade_ch/changed_650.tsv", col_sep: "\t") do |r|
    @old_650_ids[r[2].to_i] = r[0].to_i
end
print "."

@old_657_ids = {}
# Format is BM id, CH id
CSV.foreach("housekeeping/upgrade_ch/changed_657.tsv", col_sep: "\t") do |r|
    @old_657_ids[r[2].to_i] = r[0].to_i
end
print "."

@old_690_ids = {}
# Format is BM id, CH id
CSV.foreach("housekeeping/upgrade_ch/changed_690.tsv", col_sep: "\t") do |r|
    @old_690_ids[r[2].to_i] = r[0].to_i
end
print "."

@old_240_ids = {}
# Format is BM id, CH id
CSV.foreach("housekeeping/upgrade_ch/changed_240.tsv", col_sep: "\t") do |r|
    @old_240_ids[r[2].to_i] = r[0].to_i
end
print "."

@old_651_ids = {}
# Format is BM id, CH id
CSV.foreach("housekeeping/upgrade_ch/changed_651.tsv", col_sep: "\t") do |r|
    @old_651_ids[r[2].to_i] = r[0].to_i
end

@modify_590 = {}
# Format is BM id, CH id
CSV.foreach("housekeeping/upgrade_ch/changed_590b.tsv", col_sep: "\t") do |r|
    next if r[2] == "x"
    @modify_590[r[0].to_i] = {text: r[1].strip, add: r[2]}
end

@old_institutions = {}
# Format is BM id, CH id
CSV.foreach("housekeeping/upgrade_ch/changed_institutions.tsv", col_sep: "\t") do |r|
    next if r[2] == "x"
    @old_institutions[r[0].to_i] = r[1].to_i
end

@old_300a = {}
# Format is BM id, CH id
CSV.foreach("housekeeping/upgrade_ch/changed_300a.tsv", col_sep: "\t") do |r|
    if r[2]
        @old_300a["#{r[1]}: #{r[2]}"] = r[0]
    else
        @old_300a["#{r[1]}"] = r[0]
    end
end

print "."

@user_map = {
    2 => 49,    # L
    3 => 97,    # Y
    4 => 12,    # C
    7 => 343,   # G
    9 => 17,    # CB
    12 => 106,  # F
    13 => 344,  # M
    16 => 240  # MR
}

@modify_340 = {
    "Autographie" =>	"Autography",
    "Autography" =>	"Autography",
    "Fotokopien bzw. Umdrucke von Abschriften" =>	"Autography",
    "Umdruck" =>	"Autography",
    "Computer printout" =>	"Computer printout",
    "Engraving" =>	"Engraving",
    "Stich" =>	"Engraving",
    "Facsimile" =>	"Facsimile",
    "Lithografie" =>	"Lithography",
    "Lithografie [Noten]" =>	"Lithography",
    "Lithografie [p.3-16]" =>	"Lithography",
    "Lithographie" =>	"Lithography",
    "Lithography" =>	"Lithography",
    "Lithograpie" =>	"Lithography",
    "Fotocopy" =>	"Photoreproductive process",
    "Fotocopy."	 =>"Photoreproductive process",
    "Fotokopie"	 =>"Photoreproductive process",
    "Fotokopie des Autographs" =>	"Photoreproductive process",
    "Fotokopie." =>	"Photoreproductive process",
    "Heliokopie" =>	"Photoreproductive process",
    "Photocopie" =>	"Photoreproductive process",
    "Photocopy" =>	"Photoreproductive process",
    "Photocopy." =>	"Photoreproductive process",
    "Photocoy" =>	"Photoreproductive process",
    "Photokopie" =>	"Photoreproductive process",
    "Photoreproductive process"	 => "Photoreproductive process",
    "Tirage hélio" =>	"Photoreproductive process",
    "photocopy"	 => "Photoreproductive process",
    "Mechanische Reproduktion der Handschrift" =>	"Reproduction",
    "Reproduction" =>	"Reproduction",
    "Reproduction."	=> "Reproduction",
    "Reproduktion" => "Reproduction",
    "Reproduktion."	=> "Reproduction",
    "Vervielfältigung" =>	"Reproduction",
    "Vervielfältigung der Handschrift" =>	"Reproduction",
    "Vervielfältigung." =>	"Reproduction",
    "Transparentfolie" =>	"Transparency",
    "Transparentfolien"	 =>"Transparency",
    "Transparentpapier"	 =>"Transparency",
    "Typescript" =>	"Typescript",
    "Typendruck" =>	"Typography",
}

@map_593 = {
    "manuscript with autograph annotations" => "Manuscript copy with autograph annotations",
    "print with autograph annotations" => "Print with autograph annotations",
    "print with non-autograph annotations" => "Print with non-autograph annotations",
    "manuscript" => "Manuscript copy"
}

print "."
puts " done."

# We need to preserve MARC data for catalogues
# And user id for people
@save_catalogues = {}
@save_people = {}

def migrate_source(orig_source)
    mod = false
    #pb.increment!

    chmarc = orig_source.marc

    chmarc.each_by_tag("100") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_person_ids.include?(id)
            #puts "100 replace #{id} with #{@old_person_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_person_ids[id])
            mod = true
        else
            if !@save_people.keys.include?(id)
                p = Person.find(id)
                @save_people[id] = p.wf_owner if p.wf_owner && p.wf_owner > 0
            end
        end
    end

    # Fix untitled mss.
    chmarc.each_by_tag("245") do |t|
        name = fetch_single_subtag(t, "a")
        if name == "[Manuscript music, untitled]" || name == "[Printed music, untitled]"
            #puts "245 replaced [Printed music, untitled] or [Manuscript music, untitled]".green
            replace_single_subtag(t, "a", "[without title]")
            mod = true
        end
    end

    chmarc.each_by_tag("246") do |t|
        name = fetch_single_subtag(t, "a")
        if name == "[Manuscript music, untitled]" || name == "[Printed music, untitled]"
            #puts "245 replaced [Printed music, untitled] or [Manuscript music, untitled]".red
            replace_single_subtag(t, "a", "[without title]")
            mod = true
        end
    end

    chmarc.each_by_tag("340") do |t|
        id = fetch_single_subtag(t, "d")
        if @modify_340.include?(id)
            #puts "340 replace #{id} with #{@modify_340[id]}".green
            replace_single_subtag(t, "d", @modify_340[id])
        end
    end

    chmarc.each_by_tag("593") do |t|
        id = fetch_single_subtag(t, "a")
        next if !id
        if @map_593.include?(id.downcase)
            #puts "593 replace #{id.downcase} with #{@map_593[id.downcase]}".green
            replace_single_subtag(t, "a", @map_593[id.downcase])
        end
    end

    chmarc.each_by_tag("700") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_person_ids.include?(id)
            #puts "700 replace #{id} with #{@old_person_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_person_ids[id])
            mod = true
        else
            if !@save_people.keys.include?(id)
                p = Person.find(id)
                @save_people[id] = p.wf_owner if p.wf_owner && p.wf_owner > 0
            end
        end
    end

    chmarc.each_by_tag("710") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_institutions.include?(id)
            #puts "710 replace #{id} with #{@old_institutions[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_institutions[id])
            mod = true
        end
    end

    chmarc.each_by_tag("650") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_650_ids.include?(id)
            #puts "650 replace #{id} with #{@old_650_ids[id]}".green
            delete_single_subtag(t, "a")
            delete_single_subtag(t, "2") #remove $2CH-BeSRO
            replace_single_subtag(t, "0", @old_650_ids[id])
            mod = true
        end
    end

    chmarc.each_by_tag("657") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_657_ids.include?(id)
            #puts "657 replace #{id} with #{@old_657_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_657_ids[id])
            mod = true
        end
    end

    chmarc.each_by_tag("690") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_690_ids.include?(id)
            #puts "690 replace #{id} with #{@old_690_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_690_ids[id])
            mod = true
        else
            if id && !@save_catalogues.keys.include?(id) && id.to_i > 50000000
                c = Catalogue.find(id)
                @save_catalogues[id] = c.marc_source
            end
        end
    end

    chmarc.each_by_tag("651") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_651_ids.include?(id)
            #puts "651 replace #{id} with #{@old_651_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_651_ids[id])
            mod = true
        end
    end

    chmarc.each_by_tag("691") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_690_ids.include?(id)
            #puts "690 replace #{id} with #{@old_690_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_690_ids[id])
            mod = true
        else
            if id && !@save_catalogues.keys.include?(id) && id.to_i > 50000000
                c = Catalogue.find(id)
                @save_catalogues[id] = c.marc_source
            end
        end
    end

    chmarc.each_by_tag("240") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_240_ids.include?(id)
            #puts "240 replace #{id} with #{@old_240_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_240_ids[id])
            mod = true
        else
            if id.to_i > 50000000
                replace_single_subtag(t, "0", id + 100000)
            end
        end
    end

    # ALSO THE 730 CONTAINS STANDARD TITLES!
    chmarc.each_by_tag("730") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_240_ids.include?(id)
            #puts "240 replace #{id} with #{@old_240_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_240_ids[id])
            mod = true
        else
            if id.to_i > 50000000
                replace_single_subtag(t, "0", id + 100000)
            end
        end
    end

    chmarc.each_by_tag("852") do |t|
        id = fetch_single_subtag(t, "x")
        if @old_institutions.include?(id)
            #puts "852 replace #{id} with #{@old_institutions[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "x", @old_institutions[id])
        end
        delete_single_subtag(t, "0") # This tag is unused!!!
        mod = true
    end

    if @modify_590.keys.include?(orig_source.id)
        new590 = @modify_590[orig_source.id]

        chmarc.each_by_tag("590") do |t|
            b = fetch_single_subtag(t, "b")
            next if !b

            if new590[:text] == b.strip

                if new590[:add] && new590[:add] == "missing"
                    new590[:text] += " missing"
                end

                # Move it to a 500
                # BUT BEFORE! is it already there?

                new_tag = MarcNode.new("source", "500", "", "##")
                new_tag.add_at(MarcNode.new("source", "a", new590[:text], nil), 0)

                # is this is  a group?
                the8 = fetch_single_subtag(t, "8")
                if the8
                    new_tag.add_at(MarcNode.new("source", "8", the8, nil), 0)
                end

                new_tag.sort_alphabetically
                chmarc.root.children.insert(chmarc.get_insert_position(new_tag.tag), new_tag)


                # Delete the old subtag
                delete_single_subtag(t, "b")
                #puts "#{orig_source.id} Modified 590".green
            end
        end
    end

    # Migrating 300 $a should happen AFTER 590 $b is fixed
    chmarc.each_by_tag("300") do |t|
        a = fetch_single_subtag(t, "a")
        next if !a

        # is this in the manual or exclude list?
        exclude = @old_300a[a]
        next if exclude && exclude.include?("man") # Skip this

        # Copy it verbatim to 590 without spliting
        if exclude == "590$b"
            # In this case, only the 590 is filled
            a300_content = ""
            b590_content = a
            #puts "SPECIAL CASE".red
        else
            # This happens only when 300 contains "part"
            # Split it into 300 and 590
            next if !a.include? "part"

            parts = a.split(":")
            next if parts.count < 2
            a300_content = parts[0].strip
            b590_content = parts[1].strip
        end

        group = fetch_single_subtag(t, "8")
    
        # First, replace the a subtag in this 300
        #puts "300 is #{a300_content}".yellow
        replace_single_subtag(t, "a", a300_content)

        # Now we need to get the 590, if it is there.        
        added = false
        chmarc.each_by_tag("590") do |th|
            the8 = fetch_single_subtag(th, "8")

            # Can work also if both are nil when there is no group!
            if the8 == group
                th.add_at(MarcNode.new("source", "b", b590_content, nil), 0)
                th.sort_alphabetically
                added = true
                #puts "Added to 590 #{b590_content} with group #{group} id #{orig_source.id}"
            end
        end

        # No 590s there or no one matches this groups
        if !added
            new_tag = MarcNode.new("source", "590", "", "##")
            new_tag.add_at(MarcNode.new("source", "b", b590_content, nil), 0)
            new_tag.add_at(MarcNode.new("source", "8", group, nil), 0) if group # is it in a group?
            new_tag.sort_alphabetically
            chmarc.root.children.insert(chmarc.get_insert_position(new_tag.tag), new_tag)
            #puts "Added new 590 #{b590_content} with group #{group} id #{orig_source.id}"
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

    # Kill the dreaded 740
    remove_marc_tag(chmarc, "740")

    #puts orig_source.marc.to_marc if mod

    # Update the user to the BM one
    orig_source.wf_owner = @user_map[orig_source.wf_owner] if orig_source.wf_owner != nil
    orig_source.paper_trail_event = "CH Migration update authority files"

    orig_source.suppress_reindex
    orig_source.suppress_update_count
    orig_source.suppress_update_77x

    orig_source.marc.import
    
    # Just save it, we modify the user too
    #orig_source.save if mod
    orig_source.save


end


pb = ProgressBar.new(Source.count)

# Non parallel version
Source.all.each do |s|
    #next if s.id != 405000310
    orig_source = Source.find(s.id)
    migrate_source(orig_source)
    orig_source = nil
    pb.increment!
end

File.write('migration_people_ids.yml', @save_people.to_yaml)
File.write('migration_catalogues.yml', @save_catalogues.to_yaml)

=begin
@parallel_jobs = 10
@all_src = Source.all.count
@limit = @all_src / @parallel_jobs

begin_time = Time.now
  
results = Parallel.map(0..@parallel_jobs, in_processes: @parallel_jobs, progress: "Saving sources") do |jobid|
  offset = @limit * jobid

  Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
    s = Source.find(sid.id)
    migrate_source(s)
    s = nil
  end
end
=end

=begin
@parallel_jobs = 10
@all_src = Source.all.count
@limit = @all_src / @parallel_jobs

begin_time = Time.now

mutex = Mutex.new

threads = 10.times.map do |jobid|
    puts jobid
    Thread.new do
        offset = @limit * jobid

        Source.order(:id).limit(@limit).offset(offset).select(:id).each do |sid|
            s = Source.find(sid.id)
            migrate_source(s, mutex)
            s = nil
        end
    end
end
threads.each(&:join)
=end