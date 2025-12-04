# Mapping as of 23/01/2024
MAPPING = {
    "Institution.corporate_name":   "Institution.110.a",
    "Institution.place":            "Institution.110.c",
    "Institution.siglum":           "Institution.110.g",
    "Institution.subordinate_unit": "Institution.110.b",
    "LiturgicalFeast.name":         "LiturgicalFeast.name.nil", #not marc!
    "Person.full_name":             "Person.100.a",
    "Person.life_dates":            "Person.100.d",
    "Place.name":                   "Place.151.a", #not marc!
    "Publication.short_name":       "Publication.210.a",
    "Publication.title":            "Publication.240.a",
    "StandardTerm.term":            "StandardTerm.term.nil", #not marc
    "StandardTitle.title":          "StandardTitle.title.nil", #mot marc
    "Work.title":                   ["Work.100.a", "Work.130.a", "Work.130.r"], #more than one
    "WorkNode.title":               ["WorkNode.100.t", "WorkNode.100.m", "WorkNode.100.n", "WorkNode.100.r", "WorkNode.100.p"], #there is more than one!
}

marc_models = ["source", "holding", "person", "institution", "publication", "work", "work_node", "place"]
all_foreign_links = []
model_tag_map = {}
model_non_marc = {}

marc_models.each do |mm|
    model_foreign_links = []
    mc = MarcConfigCache.get_configuration(mm)

    mc.get_foreign_tag_groups.each do |tag|
        foreign_fields = []

        master = mc.get_master(tag)
        foreign_model = mc.get_foreign_class(tag, master)

        mc.each_subtag(tag) do |definition|
            st = definition[0]
            next if !mc.is_foreign?(tag, st)
            next if st == master
            foreign_fields << mc.get_foreign_field(tag, st)
        end

        foreign_fields.each {|ff| model_foreign_links << "#{foreign_model}.#{ff}".to_sym}
    end

    model_foreign_links.each do |mfl|
        tags = MAPPING[mfl.to_sym]
        referring_link = "referring_#{mm.pluralize}"

        tags = [tags] if tags.is_a? String
        tags.each do |tag|
            parts = tag.split(".")
            foreign_model = parts[0]
            foreign_tag = parts[1]
            foreign_subtag = parts[2]

            if parts[2] != "nil"

                # Add a toplevel element for the foreign item
                model_tag_map[foreign_model] = {} if !model_tag_map.keys.include?(foreign_model)

                # Add the tag elements
                model_tag_map[foreign_model][foreign_tag] = {} if !model_tag_map[foreign_model].keys.include?(foreign_tag)

                # and for the subtags...
                model_tag_map[foreign_model][foreign_tag][foreign_subtag] = [] if !model_tag_map[foreign_model][foreign_tag].keys.include?(foreign_subtag)

                # Finally add the link back!
                model_tag_map[foreign_model][foreign_tag][foreign_subtag] << referring_link if !model_tag_map[foreign_model][foreign_tag][foreign_subtag].include?(referring_link)
            
            # these are the non-marc models
            else
                model_non_marc[foreign_model] = {} if !model_non_marc.keys.include?(foreign_model)
                model_non_marc[foreign_model][foreign_tag] = [] if !model_non_marc[foreign_model].keys.include?(foreign_tag)
                model_non_marc[foreign_model][foreign_tag] << referring_link if !model_non_marc[foreign_model][foreign_tag].include?(referring_link)
            end
        end
    end


    all_foreign_links += model_foreign_links.sort.uniq
end

puts "These are the currently configured links in the marc configuration".green
puts all_foreign_links.sort.uniq
puts

puts "These are the links not present in the current mapping".green
puts all_foreign_links.sort.uniq - MAPPING.keys.sort
puts "NONE" if (all_foreign_links.sort.uniq - MAPPING.keys.sort).count == 0
puts

puts "This is the configuration for FormOptions in these models".green
model_tag_map.each do |model, val|
    val.each do |tag, subtags|
        subtags.each do |subtag, referring|
            puts "For each #{model} tag #{tag}#{subtag} add: ".yellow
            referring.each do |item|
                puts "- #{item}"
            end
            puts
        end
    end
end
puts

puts "This is the configuration for the controller of these models".green
model_non_marc.each do |model, val|
    val.each do |field, referring|
            puts "For each #{model} field #{field} add in the active_admin contoller: ".magenta
            puts referring.to_s
            puts
    end
end