@institution_map = YAML::load(File.read('housekeeping/inventories_migration/inventory_institution_map.yml'), permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Time, Date, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone])

ids = @institution_map.keys.map {|i| @institution_map[i]}

list = []
CSV.foreach("housekeeping/inventories_migration/collisions.tsv", col_sep: "\t") do |r|
    list << "#{r[0]}\t#{r[1]}\t#{r[2]}" if !ids.include? r[0].to_i
end

list.sort.uniq.each {|l| puts l}