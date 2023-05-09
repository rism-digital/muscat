File::readlines("feast_missing.txt").each do |l|
    g = l.strip.split("$0")

    t = LiturgicalFeast.where(:name => g[0])
    puts "#{t[0].id}\t#{g[0]}\t#{g[1]}\t#{g[0]}"

end