# Report holdings whose library siglum is not among the workgroup sigla of
# their owner. Run from the repository root with:
#   bin/rails runner housekeeping/correct/159_check_holding_workgroup_sigla.rb

mismatches = {}

holdings = Holding
  .where.not(wf_owner: [0, 1])
  .where.not(wf_owner: nil)
  .includes(user: [:roles, { workgroups: :institutions }])

holdings.find_each do |holding|
  owner = holding.user
  next unless owner
  next unless owner.roles.any? { |role| role.name == "cataloger" }

  workgroup_sigla = owner.workgroups
    .flat_map(&:get_institutions)
    .map(&:siglum)
    .compact
    .uniq

  next if workgroup_sigla.include?(holding.lib_siglum)

  workgroup_names = owner.workgroups.map(&:name).compact.uniq.sort
  key = [owner.id, holding.lib_siglum]
  mismatch = mismatches[key] ||= {
    owner_name: owner.name,
    workgroups: workgroup_names,
    holding_ids: []
  }
  mismatch[:holding_ids] << holding.id
end

puts "Mismatched user/siglum combinations:"
if mismatches.empty?
  puts "(none)"
else
  mismatches.sort_by { |(user_id, siglum), mismatch| [mismatch[:owner_name], user_id, siglum.to_s] }
    .each do |(user_id, siglum), mismatch|
      workgroups = mismatch[:workgroups].empty? ? "(none)" : mismatch[:workgroups].join(", ")
      holding_ids = mismatch[:holding_ids].sort.join(", ")
      puts "#{mismatch[:owner_name]} (user id #{user_id}); siglum #{siglum.inspect}; " \
           "holdings: #{holding_ids}; workgroups: #{workgroups}"
    end
end

reported_holding_count = mismatches.values.sum { |mismatch| mismatch[:holding_ids].length }
puts "Found #{reported_holding_count} holding(s) in #{mismatches.length} mismatched user/siglum combination(s)."
puts "Cataloger owners with mismatches:"
if mismatches.empty?
  puts "(none)"
else
  owners = mismatches.each_with_object({}) do |((user_id, _siglum), mismatch), collected|
    collected[user_id] = mismatch
  end
  owners.sort_by { |user_id, mismatch| [mismatch[:owner_name], user_id] }.each do |user_id, mismatch|
    workgroups = mismatch[:workgroups].empty? ? "(none)" : mismatch[:workgroups].join(", ")
    puts "#{mismatch[:owner_name]} (user id #{user_id}); workgroups: #{workgroups}"
  end
end
