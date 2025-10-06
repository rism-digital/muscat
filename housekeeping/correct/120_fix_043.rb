mc = MarcConfigCache.get_configuration("person")

Person.find_each(batch_size: 500) do |p|
  do_save = false

  p.marc["043"].each do |t|
     if t["c"].count > 1
      puts p.id

      do_save = true
        codes = t["c"].map {|tt| tt.content}

        # adios
        t["c"].each(&:destroy_yourself)

        # Add back the first one
        t.add_at(MarcNode.new("person", "c", codes.shift, nil), 0 )
        t.sort_alphabetically

        # Create new ones
        codes.each do |code|
          a043 = MarcNode.new("person", "043", "", mc.get_default_indicator("043"))
   
          a043.add_at(MarcNode.new("person", "c", code, nil), 0 )
          a043.sort_alphabetically
          p.marc.root.add_at(a043, p.marc.get_insert_position("043") )
        end
     end
  end

  p.paper_trail_event = "Split 043"
  p.save if do_save

end