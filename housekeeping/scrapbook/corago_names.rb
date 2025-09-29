exact_matches = {}
maybe_matches = {}
not_found = []

CSV::foreach("NOMI_CORAGO_NOME.csv") do |line|

    #name = "#{line[0]}, #{line[1]}"
    name = [line[0]&.strip, line[1]&.strip].compact.join(', ')

    prs = Person.where(full_name: name)
    if prs.count > 0
        prs.each do |pr|
            #puts "#{pr.id} #{name}"
            exact_matches[name] ||= Array.new
            exact_matches[name] << {muscat_id: pr.id, muscat_name: pr.full_name, corago_name: name}
        end
    else

        res = Person.solr_search do
            adjust_solr_params do |p|
                p["q.op"] = "AND"
              end
            fulltext name, :fields => [:full_name,  :"400a"]
            #fulltext sanit_name, :fields => :"400a"
            #with "full_name_or_400a", sanit_name
        end

        if res.results.count > 0
            #puts name.yellow
            res.results.each do |pp|
                #puts pp.full_name.green
                maybe_matches[name] ||= Array.new
                maybe_matches[name] << {muscat_id: pp.id, muscat_name: pp.full_name}
            end
        else
            not_found << name
        end
        sleep(0.005)
    end

end

sheet = RODF::Spreadsheet.new
table_single = sheet.table("Exact matches, single")
table_multiple = sheet.table("Exact matches, multiple")
maybe_single = sheet.table("Maybe, single")
maybe_multiple = sheet.table("Maybe, multiple")

exact_matches.each do |name, mus|
    row = mus.count == 1 ? table_single.row : table_multiple.row
    row.cell(name)

    mus.each do |mm|
        row.cell(mm[:muscat_id])
        row.cell(mm[:muscat_name])
    end
end

maybe_matches.each do |name, mus|
    row = mus.count == 1 ? maybe_single.row : maybe_multiple.row
    #row = table.row
    row.cell(name)

    mus.each do |mm|
        row.cell(mm[:muscat_id])
        row.cell(mm[:muscat_name])
    end
end

table = sheet.table("Not found")
not_found.each do |nf|
    row = table.row
    row.cell(nf)
end

sheet.write_to "corago2muscat.ods"