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
print "."

# Just one!
# 30000010	CH-MÜ	50000010	CH-MÜ
# 50006835 => 30079405 is CH-FI, which did not show up?
# 50007932 => 30080410 CH-NYan
@old_852_ids = {50000010 => 30000010, 50006835 => 30079405, 50007932 => 30080410}
print "."
puts " done."

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
        end
    end

    chmarc.each_by_tag("700") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_person_ids.include?(id)
            #puts "700 replace #{id} with #{@old_person_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_person_ids[id])
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
        end
    end

    chmarc.each_by_tag("240") do |t|
        id = fetch_single_subtag(t, "0")
        if @old_240_ids.include?(id)
            #puts "240 replace #{id} with #{@old_240_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "0", @old_240_ids[id])
            mod = true
        end
    end

    chmarc.each_by_tag("852") do |t|
        id = fetch_single_subtag(t, "x")
        if @old_852_ids.include?(id)
            #puts "852 replace #{id} with #{@old_852_ids[id]}".green
            delete_single_subtag(t, "a")
            replace_single_subtag(t, "x", @old_852_ids[id])
        end
        delete_single_subtag(t, "0") # This tag is unused!!!
        mod = true
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

    orig_source.suppress_reindex
    orig_source.suppress_update_count
    orig_source.suppress_update_77x

    orig_source.marc.import
    orig_source.paper_trail_event = "CH Migration update authority files"
    orig_source.save if mod
end


pb = ProgressBar.new(Source.count)

# Non parallel version
Source.all.each do |s|
    orig_source = Source.find(s.id)
    migrate_source(orig_source)
    orig_source = nil
    pb.increment!
end

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
