
responses = {}
CSV::foreach("f-tempo-rism-d-mbs.tsv", col_sep: "\t") do |r|

    

    manifest = r[0]
    siglum = r[1]
    title = r[2]

    response = Net::HTTP.get(URI(manifest))
    items = JSON.parse(response)

    items["seeAlso"].each do |sals|
        if sals["label"] == "MARCXML"

            elem = sals["@id"]

            elem_res = Net::HTTP.get(URI(elem))

            responses[manifest] = elem_res
        end
    end


end

File.open("dnb_marc.yml", "w") { |file| file.write(responses.to_yaml) }
