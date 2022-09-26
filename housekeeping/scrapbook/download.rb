all_permlinks = []
for i in 0..164

    start = i * 1000

    uri = URI("https://imslp.org/imslpscripts/API.ISCR.php?account=worklist/disclaimer=accepted/sort=id/type=2/start=#{start}/retformat=json")

    #http = Net::HTTP.new(uri.host, uri.port)
    #request = Net::HTTP::Get.new(uri.request_uri)

    response = Net::HTTP.get(uri)

    items = JSON.parse(response)

    items.each do |item|
        subitem = item[1]
        if subitem.include?("permlink")
            all_permlinks << subitem["permlink"]
        end
    end
    puts i
end

File.open("permlinks.yml", "w") { |file| file.write(all_permlinks.to_yaml) }
