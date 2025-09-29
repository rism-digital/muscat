spinner = TTY::Spinner.new("[:spinner] :title", format: :shark)

spinner.update(title: "Fixing sources...")
spinner.auto_spin

Source.where("marc_source LIKE '%=981 %'").each do |s|
    tgs = s.marc.by_tags("981")

    next if !tgs or tgs.empty?

    if tgs.count > 4
        new_set = Array.new
        new_set << tgs[0].deep_copy

        for i in 4.downto(1) do new_set << tgs[tgs.length - i].deep_copy end

        s.marc.by_tags("981").each {|t| t.destroy_yourself}

        new_set.each {|ntag| s.marc.root.add_at(ntag, s.marc.get_insert_position("981") ) }
        s.save
    end
end