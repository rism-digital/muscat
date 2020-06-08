headers = [:man_a, :ignore_b, :collid_c, :ignore_d, :childid_e, :ignore_f, :childindex_g, :holding_h, :origtemplate_child_i, :newtemplatechild_j, :done_k]
composites = {}

## Some marc navigating functions
# shamelessly copied from the CH migration
def fetch_single_subtag(marctag, subtag)
    st = marctag.fetch_first_by_tag(subtag)
    if st && st.content
      return st.content
    end
    return nil
end

def insert_single_marc_tag(marc, tag, subtag, value)
    new_tag = MarcNode.new("source", tag, "", "##")
    new_tag.add_at(MarcNode.new("source", subtag, value, nil), 0)
    new_tag.sort_alphabetically
    marc.root.children.insert(marc.get_insert_position(tag), new_tag)
end

def tag_contains_value(marctag, subtag, value)
    marctag.each_by_tag(subtag) do |st|
        next if !st || !st.content
        return true if st.content == value
    end
    false
end

def copy_tag(marc, new_marc, tag, new_tag_name = nil)
    marc.by_tags(tag).each do |old_tag|            
        new_tag = old_tag.deep_copy
        if new_tag_name
            new_tag.tag = new_tag_name
        end
        new_marc.root.children.insert(new_marc.get_insert_position(new_tag.tag), new_tag)
    end
end

def move_tag_with_subtag(marc, new_marc, tag, subtag, subtag_val)
    marc.by_tags(tag).each do |old_tag|   
        next if !tag_contains_value(old_tag, subtag, subtag_val)

        new_tag = old_tag.deep_copy
        new_marc.root.children.insert(new_marc.get_insert_position(new_tag.tag), new_tag)
        old_tag.destroy_yourself
    end
end

def remove_marc_tag(marc, tag)
    marc.by_tags(tag).each {|t| t.destroy_yourself}
end

def migrate_590(new_marc, the590)
    the8 = nil
    # pull the 852
    the852 = new_marc.first_occurance("852")
    the8 = the852.fetch_first_by_tag("8") if the852
    if the8 && the8.content
        # Substitute the existing one
        the8.content = fetch_single_subtag(the590, "a")
    else
        # Append a new one
        the852.add_at(MarcNode.new("source", "q", fetch_single_subtag(the590, "a"), nil), 0)
        the852.sort_alphabetically
    end
end

# End shameless copying

def ms2print(composite, child)
    child_source = Source.find(child[:id])
    marc = child_source.marc

    if !composite.record_type == MarcSource::RECORD_TYPES[:collection]
        # We should have 0, check the data!
        puts "Parent is not a collection #{composite.record_type} #{child[:id]}"
        return
    end

    # Copy the 852 to a new holding record
    holding = Holding.new

    new_marc = MarcHolding.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc"))

    # Kill empty
    remove_marc_tag(new_marc, "852")

    # Move the tags from the MS to the Holding
    copy_tag(marc, new_marc, "300")
    
    copy_tag(marc, new_marc, "506")
    copy_tag(marc, new_marc, "541")
    copy_tag(marc, new_marc, "561")
    copy_tag(marc, new_marc, "563")
    copy_tag(marc, new_marc, "591")
    copy_tag(marc, new_marc, "592")

    move_tag_with_subtag(marc, new_marc, "700", "4", "fmo")
    move_tag_with_subtag(marc, new_marc, "700", "4", "scr")
    move_tag_with_subtag(marc, new_marc, "700", "4", "dpt")

    move_tag_with_subtag(marc, new_marc, "710", "4", "fmo")
    move_tag_with_subtag(marc, new_marc, "710", "4", "scr")
    move_tag_with_subtag(marc, new_marc, "710", "4", "dpt")

    copy_tag(marc, new_marc, "852")
    copy_tag(marc, new_marc, "856")

    # Copy the 590s, after the 852 is created
    marc.each_by_tag("590") {|tgs| migrate_590(new_marc, tgs)}

    # Remove the tags in the old marc
    remove_marc_tag(marc, "506")
    remove_marc_tag(marc, "541")
    remove_marc_tag(marc, "561")
    remove_marc_tag(marc, "563")
    remove_marc_tag(marc, "591")
    remove_marc_tag(marc, "592")
    remove_marc_tag(marc, "852")
    remove_marc_tag(marc, "856")


    # Import the marc
    new_marc.suppress_scaffold_links
    new_marc.import
    
    # Attach it to the child
    holding.marc = new_marc
    holding.source = child_source
    
    # Save the holding
    holding.suppress_reindex
    
    holding.save
    puts "Created holding #{holding.id} to #{child_source.id}"

    child_source.record_type = MarcSource::RECORD_TYPES[:edition]
    child_source.suppress_update_77x
    child_source.save
    puts "#{child_source.id} is now a print"
end

def print2ms(composite, child)
    child_source = Source.find(child[:id])
    puts "DO NOTHING p to m!!! #{child_source.id}".bold
end

def duplicate_holding(composite, child_source)
        # we need to make a duplicate of the parent's record holding
        # First, make a holding record
        holding = Holding.new

        new_marc = MarcHolding.new(composite.holdings.first.marc.marc_source)
        # Reset the basic fields to default values
        new_marc.first_occurance("001").content = "__TEMP__"
        remove_marc_tag(new_marc, "973")

        # Import the marc
        new_marc.suppress_scaffold_links
        new_marc.import
        
        # Attach it to the child
        holding.marc = new_marc
        holding.source = child_source
        
        # Save the holding
        holding.suppress_reindex
        
        holding.save
        puts "Added holding #{holding.id} to #{child_source.id}"
end

# This happens only when the collection is a edition parent record
def child2parent(composite, child)
    child_source = Source.find(child[:id])

    # duplicate the holding record from the parent
    if !composite.record_type == MarcSource::RECORD_TYPES[:edition]
        # We should have 0
        puts "Not a parent #{composite.record_type} #{child[:id]}"
        return
    end

    # No holding? Copy it from parent
    if child_source.holdings.count == 0
        duplicate_holding(composite, child_source)
    end

    # Make the child into a print
    child_source.record_type = MarcSource::RECORD_TYPES[:edition]
    child_source.suppress_update_77x
    child_source.save
    puts "#{child_source.id} is now a parent edition"
end

def parent2child(child)
    # We need to merge the holding in the record
    # the remove the holding
    child_source = Source.find(child[:id])

    if child_source.holdings.count > 1
        Puts "#{child_source.id} has #{child_source.holdings.count} holdings".red
    end

    holding = child_source.holdings.first

    copy_tag(holding.marc, child_source.marc, "300")

    # Sayonara
    child_source.holdings.destroy_all
    puts "Purged holdings for #{child_source.id}".yellow

    child_source.record_type = MarcSource::RECORD_TYPES[:edition_content]
    child_source.suppress_reindex
    child_source.suppress_recreate
    child_source.suppress_update_77x
    child_source.suppress_update_count
    child_source.save
end

# Prints need to have the appropriate 973 in the holding
# and the "special" 774 in the parent
def adapt_print_link(composite, child)
    child_source = Source.find(child[:id])

    a = composite.marc.by_tags_with_subtag(["774"], "w", child[:id])
    # legacy value!
    b = composite.marc.by_tags_with_subtag(["774"], "w", "00000#{child[:id]}")

    if (a + b).empty?
        # In some rare cases, there was no 774 in the original ms...
        # if the source_id of the child is set, we need to add one
        # and continue
        # Create a brand new 774 and add it to the parent
        mc = MarcConfigCache.get_configuration("source")
        w774 = MarcNode.new("source", "774", "", mc.get_default_indicator("774"))
        w774.add_at(MarcNode.new("source", "w", child_source.id.to_s, nil), 0 )
        composite.marc.root.add_at(w774, composite.marc.get_insert_position("774") )
        # Now add it in our array, I know it is a lazy way to do ie
        a << w774

        puts "No child #{child[:id]} found in #{composite.id}, adding it".green
    end

    if (a + b).count > 1
        puts "Multiple child occurances #{child[:id]} in #{composite.id}".blue
        return
    end

    link = (a + b)[0]
    begin
        holding_id = child[:holding_id] ? child[:holding_id] : child_source.holdings.first.id
    rescue NoMethodError
        puts "Child #{child[:id]} in #{composite.id} has no holdings".red
        return
    end

    # Change the ID in the 774 to the holding id
    link.fetch_first_by_tag("w").content = holding_id.to_s

    # Now add the $4 "holding" identifier
    link.add_at(MarcNode.new("source", "4", "holding", nil), 0 )
    link.sort_alphabetically

    # Next step is fixing the holding itsef
    holding = Holding.find(holding_id)

    # Make a 973 from scratch with the Source Id
    mc = MarcConfigCache.get_configuration("holding")
    u973 = MarcNode.new("holding", "973", "", mc.get_default_indicator("973"))
    u973.add_at(MarcNode.new("holding", "u", composite.id.to_s, nil), 0 )
    # Add the 973 to the tree
    holding.marc.root.add_at(u973, holding.marc.get_insert_position("973") )
    # Add the DB link
    holding.collection_id = composite.id
    #... and save the holding
    holding.suppress_update_77x
    holding.save
    # Make it recreate the links
    h2 = Holding.find(holding.id)
    h2.marc.load_source true
    h2.suppress_update_77x
    h2.save

    # Last step, purge the 774 link from the child
    cs = Source.find(child[:id])
    remove_marc_tag(cs.marc, "773")
    cs.source_id = nil # We are attached to a composite
    cs.suppress_update_77x
    cs.save

    puts "Fixed child #{child[:id]} to #{composite.id}"
    return holding
end

def process_child(composite, child)
    link_to_composite = nil
    if !child[:new_template]
        # For print we need to move the link
        # from the print to the holding
        link_to_composite = adapt_print_link(composite, child) if child[:old_template] == "p" 
        # NOTE: the case "m" does nothing as the linking already works
        puts "c #{child[:id]}" if child[:old_template] == "c"  # This snould not happen! correct the data
        # The case "m" is not touched
    else
        # Child record gets "upgraded" to print parent
        # NOTE: there are no cases when the composite is a manuscript
        if child[:old_template] == "c" && child[:new_template] == "p"
            child2parent(composite, child) # Make it into a parent
            link_to_composite = adapt_print_link(composite, child) # Fix the linking to the composite
        elsif child[:old_template] == "m" && child[:new_template] == "p"
            ms2print(composite, child) # Make the MS a print
            link_to_composite = adapt_print_link(composite, child) # then fix the linking to the composite
        elsif child[:old_template] == "p" && child[:new_template] == "m"
            # in this case a pr becomes a ms
            # there seems to be only one, just do nothing
            print2ms(composite, child)
        end
    end
    return link_to_composite
end

def create_or_copy_holding_for_collection(composite, collection) 
    holding = Holding.new

    if (composite.record_type == MarcSource::RECORD_TYPES[:edition])
        new_marc = MarcHolding.new(composite.holdings.first.marc.marc_source)
        # Reset the basic fields to default values
        new_marc.first_occurance("001").content = "__TEMP__"
        remove_marc_tag(new_marc, "973")
    else
        new_marc = MarcHolding.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc"))
        # Reset the basic fields to default values
        new_marc.first_occurance("001").content = "__TEMP__"
        remove_marc_tag(new_marc, "973")

        # The 852 comes from the composite!
        copy_tag(composite.marc, new_marc, "852")
        copy_tag(composite.marc, new_marc, "300")
    end

    # Make a 973 to tie the holding to the composite
    mc = MarcConfigCache.get_configuration("holding")
    u973 = MarcNode.new("holding", "973", "", mc.get_default_indicator("973"))
    u973.add_at(MarcNode.new("holding", "u", composite.id.to_s, nil), 0 )
    # Add the 973 to the tree
    new_marc.root.add_at(u973, new_marc.get_insert_position("973") )

    # Import the marc
    new_marc.suppress_scaffold_links
    new_marc.import
    
    # Attach it to the child
    holding.marc = new_marc
    holding.source = collection
    holding.collection_id = composite.id
    
    # Save the holding
    holding.suppress_reindex
    holding.suppress_update_77x
    holding.save
    # Make it recreate the links
    h2 = Holding.find(holding.id)
    h2.marc.load_source true
    h2.suppress_update_77x
    h2.save

    puts "Added holding #{holding.id} to #{collection.id}"
    return holding
end

def make_collection(composite, children)

    # First, we need to make a scratch print collection
    collection = Source.new
    collection.record_type = MarcSource::RECORD_TYPES[:edition]
    new_marc = MarcSource.new(File.read( "#{Rails.root}/config/marc/#{RISM::MARC}/source/011_edition.marc"), MarcSource::RECORD_TYPES[:edition])

    # Purge the default marc
    remove_marc_tag(new_marc, "240")
    remove_marc_tag(new_marc, "691")
    remove_marc_tag(new_marc, "700")
    remove_marc_tag(new_marc, "710")

    # Copy some basic stuff from the composite
    copy_tag(composite.marc, new_marc, "100")
    copy_tag(composite.marc, new_marc, "240")
    copy_tag(composite.marc, new_marc, "245")
    copy_tag(composite.marc, new_marc, "593")
    copy_tag(composite.marc, new_marc, "650")
    copy_tag(composite.marc, new_marc, "691")
    copy_tag(composite.marc, new_marc, "700")
    copy_tag(composite.marc, new_marc, "710")

    # Import the marc
    new_marc.suppress_scaffold_links
    new_marc.import

    # And save the fresh collection
    collection.marc = new_marc
    collection.save

    # Now we need to add a holding to it
    # If the composite is a MS, copy 852
    # Else duplicate the first holding
    holding = create_or_copy_holding_for_collection(composite, collection)

    # Now we need to link the holding into the composite
    mc = MarcConfigCache.get_configuration("source")
    w774 = MarcNode.new("source", "774", "", mc.get_default_indicator("774"))
    w774.add_at(MarcNode.new("source", "w", holding.id.to_s, nil), 0 )
    w774.add_at(MarcNode.new("source", "4", "holding", nil), 0 )
    w774.sort_alphabetically
    composite.marc.root.add_at(w774, composite.marc.get_insert_position("774") )

    puts "created #{collection.id} from #{composite.id}"

    # We need to detach the children from the composite
    # And attach them to the new collection 
    children.each do |child|
        # Do we need to transform the child? 
        parent2child(child) if child[:new_template] == "c" && child[:old_template] == "p"
        
        child_source = Source.find(child[:id])

        # First step, nuke the 774 from the composite
        composite.marc.each_data_tag_from_tag("774") do |tag|
            subfield = tag.fetch_first_by_tag("w")
            next if !subfield || !subfield.content
            if subfield.content.to_i == child_source.id
                puts "Deleting 774 $w#{subfield.content} for #{composite.id}, from #{child_source.id}"
                tag.destroy_yourself
            end
        end

        # Remove the eventual old 773
        remove_marc_tag(child_source.marc, "773")

        # Add the 773 link in the child to the collection
        mc = MarcConfigCache.get_configuration("source")
        w773 = MarcNode.new("source", "773", "", mc.get_default_indicator("773"))
        w773.add_at(MarcNode.new("source", "w", collection.id, nil), 0 )

        child_source.marc.root.add_at(w773, child_source.marc.get_insert_position("773") )
        # This will recreate the 774 in the collection
        child_source.source_id = collection.id
        child_source.suppress_reindex
        child_source.save
        puts "Added 773 #{child_source.id} to #{collection.id}"
        
        # Fix linking
        c2 = Source.find(child_source.id)
        c2.suppress_reindex
        c2.save
    end

    return holding
end

CSV::foreach("housekeeping/ch_composite/composites.csv", col_sep: "\t", headers: headers) do |r|

    composite_id = r[:collid_c]
    child_id = r[:childid_e]

    if child_id == nil
        puts "#{composite_id}".red
        next
    end

    if !composites.keys.include?(composite_id)
        composites[composite_id] = {}
    end

    if r[:childindex_g] == nil || r[:childindex_g].empty?
        composites[composite_id]["item_#{child_id}"] = {id: child_id, holding_id: r[:holding_h], new_template: r[:newtemplatechild_j], old_template: r[:origtemplate_child_i]}
    else
        if !composites[composite_id].keys.include?("collection_#{r[:childindex_g]}")
            composites[composite_id]["collection_#{r[:childindex_g]}"] = []
        end
        composites[composite_id]["collection_#{r[:childindex_g]}"] << {id: child_id, holding_id: r[:holding_h], new_template: r[:newtemplatechild_j], old_template: r[:origtemplate_child_i]}
    end
end

composites.each do |id, elements|
    ms_count = 0
    pr_count = 0
    ordering = []
    collection = Source.find(id)
    #next if collection.id != 400102853

    elements.each do |type, children|
        if type.starts_with?("item_")
            link = process_child(collection, children) ## only one child in this case
        else
            link = make_collection(collection, children)
        end
        ordering << {item: type, id: link ? link.id : nil, type: link ? link.class : nil}
    end

    # Now we need to fix the positioning...
    links = collection.marc.by_tags("774").count

    if links > ordering.count
        puts "Manual check: #{collection.id} #{links} vs #{ordering.count}".red
    else
        # Nuke and recreate 774s
        remove_marc_tag(collection.marc, "774")

        #Re-create them in the correct order
        ordering.each do |order|
            if order[:id] == nil
                id = order[:item].split("_")[1] 
            else
                id = order[:id]
            end

            mc = MarcConfigCache.get_configuration("source")
            w774 = MarcNode.new("source", "774", "", mc.get_default_indicator("774"))
            w774.add_at(MarcNode.new("source", "w", id, nil), 0 )
            w774.add_at(MarcNode.new("source", "4", "holding", nil), 0 ) if order[:type] && order[:type] == Holding
            w774.sort_alphabetically
            collection.marc.root.add_at(w774, collection.marc.get_insert_position("774") )

            if order[:type] == Holding
                pr_count += 1
            else
                ms_count += 1
            end
        end
    end

    if pr_count == 0
        txt = "Composite volume with #{ms_count} manuscript copies"
    elsif ms_count == 0
        txt = "Composite volume with #{pr_count} printed music editions"
    else
        txt = "Composite volume with #{pr_count}  printed music editions and #{ms_count} manuscript copies"
    end

    insert_single_marc_tag(collection.marc, "520", "a", txt)

    # move the holding record if any to the composite
    if collection.holdings.count > 0
        puts "WARNING multiple holdings in #{collection.id}" if collection.holdings.count > 1
        h = collection.holdings.first # always use the first one
        copy_tag(h.marc, collection.marc, "852")
        copy_tag(h.marc, collection.marc, "541")
        copy_tag(h.marc, collection.marc, "561")
        copy_tag(h.marc, collection.marc, "700")
        copy_tag(h.marc, collection.marc, "710")
        copy_tag(h.marc, collection.marc, "500")
        copy_tag(h.marc, collection.marc, "599")

        collection.holdings.destroy_all
    end

    # make it a composite volume
    collection.record_type = MarcSource::RECORD_TYPES[:composite_volume]
    collection.save

end