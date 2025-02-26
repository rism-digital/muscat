exact_matches = {}
maybe_matches = {}
not_found = []

CSV::foreach("NOMI_CORAGO_NOME.csv") do |line|

    name = "#{line[0]}, #{line[1]}"

    prs = Person.where(full_name: name)
    if prs.count > 0
        prs.each do |pr|
            #puts "#{pr.id} #{name}"
            exact_matches[name] |= Array.new
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
            puts name.yellow
            res.results.each do |pp|
                #puts pp.full_name.green
                maybe_matches[name] |= Array.new
                maybe_matches[name] << {muscat_id: pr.id, muscat_name: pr.full_name}
            end
        else
            not_found << name
        end

    end

end

sheet = RODF::Spreadsheet.new
table = sheet.table("Exact matches")

exact_matches.each do |name, mus|
    row = table.row
    row.cell(name)
    row.cell(mus.first[:muscat_id])
    row.cell(mus.first[:muscat_name])
end

sheet.write_to "corago2muscat.ods"