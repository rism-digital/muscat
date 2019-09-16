headers = %w(none id ms_245 pr_245 move_500 move_505 move_691 action split_group purge_group merge_group add_holding_to target_id )

items = []

CSV::foreach("migrate_short.csv", headers: headers) do |r|
    next if !r["action"]
    next if r["action"].downcase.include?("man")
    items << r["action"].strip
end

ap items.sort.uniq