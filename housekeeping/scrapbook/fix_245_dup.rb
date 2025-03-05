
pattern = /\[([^\];]+)(;\s*\1)+\]/

Source.where(record_type: 8).each do |s|

    s.marc.load_source false

    text = taf245 = s.marc.first_occurance("245", "a")&.content

    text.scan(pattern) do |match|
        res = $&
        fixed = res.gsub("[", "").gsub("]", "").split(";").first.strip
        puts "#{s.id}\t#{res}\t[#{fixed}]"
    end

end