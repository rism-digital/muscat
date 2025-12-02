
editor_profile = EditorConfiguration.get_default_layout Place.first

code_values = SharedCodes::get("country_codes_043")

manual_patch = {
  "Bosnia and Herzegovina": "Bosna i Hercegovina",
  "Iran, Islamic Republic of": "Iran",
  "Korea, Republic of": "Han'guk",
  "Turkey": "Türkiye",
  "United States of America": "United States",
  "Venezuela, Bolivarian Republic of": "Venezuela",
  "India": "Bhārat"
}

map = {}

code_values.each do |code|
  name = editor_profile.get_label(code)
  next if name.include?(":")

  name = manual_patch[name.strip.to_sym] if manual_patch.keys.include?(name.strip.to_sym)

  begin
    tgn = TgnClient::search(name).select {|a| a[:type].include?("nations")}
  rescue Faraday::TimeoutError
    puts "#{name} failed"
    next
  end
  puts "#{name} #{code}" if tgn.empty?
  #ap tgn
  #sleep 2
  map[tgn.first[:subject]] = code if !tgn.empty?
end

#Hong Kong: 7004543
#Taiwan: 1000141
#Puerto Rico: 7004643
#Trinidad and Tobago: 7004787

map["tgn:1000141"] = "XB-TW"
map["tgn:7004543"] = "XB-HK"
map["tgn:7004643"] = "XD-PR"
map["tgn:7004787"] = "XD-TT"

ap map

#TgnClient::search("Bulgaria").select {|a| a[:type].include?("nations")}