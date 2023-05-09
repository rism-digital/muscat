sheet = RODF::Spreadsheet.new
matching_std_title_table = sheet.table("Matching Standard Term")
no_match_table = sheet.table("No Match")
suggestions = sheet.table("Suggested 650s")
multiples = sheet.table("Multiple 650s in the same record")

header = matching_std_title_table.row
header.cell("ID")
header.cell("240 $a")
header.cell("Matching Standard Term")

header = no_match_table.row
header.cell("ID")
header.cell("240 $a")

header = suggestions.row
header.cell("ID")
header.cell("240 $a")
header.cell("Parent 650")
header.cell("Suggested 650")

header = multiples.row
header.cell("ID")
header.cell("650 values")

pb = ProgressBar.new(203572) # wc -l is my friend

uniques = []

File.open("missing650list.txt").each_line do |line|
    s = Source.find(line)

    title =  s.marc.first_occurance("240", "a").content

    std_title_records = StandardTerm.where(term: title)

    #std_title = std_title_records.count > 0 ? std_title_records.first.title : ""

    #puts "#{s.id}\t#{title}\t#{std_title}"

    #puts title if title =~ /^\d/
    #next

    if std_title_records.count > 0
        row = matching_std_title_table.row
        row.cell(s.id)
        row.cell(title)
        row.cell(std_title_records.first.term)
        row.cell(std_title_records.first.id)
    else
        found_in_parent = false
        if s.parent_source
            s.parent_source.marc.load_source false

            # there is a 650
            t = s.parent_source.marc.first_occurance("650", "a")
            if t && t.content
                found_in_parent = true # make sure it does not end in the NO MATCH table
                # one or multiple?
                if s.parent_source.marc.root.fetch_all_by_tag("650").size > 1
                    # Multiples, go to the multiple tables
                    row = multiples.row
                    row.cell(s.id)
                    s.parent_source.marc.root.fetch_all_by_tag("650").each do |t|
                        t.fetch_all_by_tag("a").each do |tn|
                            row.cell(tn.content) if tn.content
                        end
                    end
                else
                    # Just one! make a suggestion
                    term = StandardTerm.where(term: t.content)
                    row = suggestions.row
                    row.cell(s.id)
                    row.cell(title)
                    row.cell(t.content)
                    row.cell(term.first.term)
                    row.cell(term.first.id)
                end
            else
                # Try to see if this dude is elegible for a 650...
                title_on_parent =  s.parent_source.marc.first_occurance("240", "a").content
                parent_terms = StandardTerm.where(term: title_on_parent)
                if parent_terms.count > 0
                    found_in_parent = true
                    row = suggestions.row
                    row.cell(s.id)
                    row.cell(title)
                    row.cell("See 'Matching' table for #{s.parent_source.id}")
                    row.cell(parent_terms.first.term)
                    row.cell(parent_terms.first.id)
                end
            end
        end

        if !found_in_parent && !line.start_with?("850")
            row = no_match_table.row
            row.cell(s.id)
            row.cell(title)
            uniques << title
        end
    end

    s = nil
    pb.increment!
end

unique_terms = sheet.table("Unique terms")
header = unique_terms.row
header.cell("Unique term")
uniques.sort.uniq.each do |uu|
    row = unique_terms.row
    row.cell(uu)
end

sheet.write_to 'missing_650_proposed.ods'