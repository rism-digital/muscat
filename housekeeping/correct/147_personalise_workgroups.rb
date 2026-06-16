converted = 0
created = 0
skipped = 0

User.includes(:workgroups).find_each do |user|
  if Workgroup.exists?(owner_user_id: user.id, personal_default: true)
    puts "SKIP user=#{user.id}: already has default workgroup"
    skipped += 1
    next
  end

  workgroups = user.workgroups.to_a

  if workgroups.empty?
    workgroup = Workgroup.create!(
      personal_default: true,
      owner_user_id: user.id,
      name: "Default for #{user.username.presence || user.email}"
    )

    user.workgroups << workgroup

    puts "CREATED user=#{user.id}, workgroup=#{workgroup.id}"
    created += 1
    next
  end

  unless workgroups.size == 1
    skipped += 1
    next
  end

  workgroup = workgroups.first

  unless workgroup.users.count == 1
    puts "SKIP user=#{user.id}, workgroup=#{workgroup.id}: workgroup is shared"
    skipped += 1
    next
  end

  workgroup.update!(
    personal_default: true,
    owner_user_id: user.id,
    name: "Default for #{user.username.presence || user.email}"
  )

  puts "CONVERTED user=#{user.id}, workgroup=#{workgroup.id}"
  converted += 1
end

puts "Done. Created: #{created}, converted: #{converted}, skipped: #{skipped}"