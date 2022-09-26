items = %w(
402010655
402010656
402010657
402010783
402010257
402010261
402010248
402010247
402010635
402010246
402010258
402010679
402010643
402010650
402010636
402010360
402010573
402010651
402010642
402010264
402010265
402010266
402010267
402010268
402010143
402010144
402010145 
402010652
402010653
402010654
402010644
402010645
402010646 
402010647
402010648
402010649 
402010146
402010147
402010148
402010539
402010540
402010541 
402010542
402010543
402010544 
402010249
402010523
402010326
402010121
)


items.each do |sid|
    s = Source.find(sid)

    next if s.record_type != 3 && s.record_type != 8


    if s.parent_source
        puts "#{s.id} #{s.parent_source.holdings.count} #{s.record_type}"
        holding = s.parent_source.holdings.first
    else
        puts "#{s.id} #{s.holdings.count} #{s.record_type}"
        holding = s.holdings.first
    end

    holding.marc.all_tags.each do |t|
        nt = t.deep_copy

        s.marc.root.add_at(nt, s.marc.get_insert_position(nt.tag) )
    end

    s.record_type = 1 if s.record_type == 8
    s.record_type = 2 if s.record_type == 3

    s.save
end

items.each do |sid|
    s = Source.find(sid)

    if s.holdings
        s.holdings.each {|h| h.delete}
    end
end