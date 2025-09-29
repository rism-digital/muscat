Source.by_shelf_mark_and_siglum_contains("(Ms.", "CH").each do |s|

    match_data = s.shelf_mark.match(/\((Ms.[^)]*)\)/)
    ms = ""
    ms = match_data[1] if match_data

    puts "#{s.id}\t#{s.lib_siglum}\t#{s.shelf_mark}\t#{ms}"

end