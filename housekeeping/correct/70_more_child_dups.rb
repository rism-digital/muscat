
def find_duplicates(array)
    duplicates = []
    array.each do |element|
      duplicates << element if array.count(element) > 1
    end
    duplicates.uniq
  end

def count_items(s)
    names = []
    total_items = s.marc.by_tags("774").count
    s.marc.each_by_tag("774") do |link|
        link_id = link.fetch_first_by_tag("w")
        link_type = link.fetch_first_by_tag("4")
        next if !link_id || !link_id.content
        holding_link = true if link_type && link_type.content && link_type.content == "holding"
        if holding_link
            holding = s.get_collection_holding(link_id.content.to_i)
            child = holding.source if holding && holding.source
        else
            child = s.get_child_source(link_id.content.to_i)
        end

        if child
            name = child.composer ? child.composer : ""
            name += " "
            name += child.std_title ? child.std_title : ""
        end
        names << name
    end

    return names
end


Source.where(record_type: 8).each do |s|

    next if !s.marc_source.include?("This record replaces")

    d = find_duplicates(count_items(s))

    if !d.empty?
        puts(s.id)
        ap d
    end

end