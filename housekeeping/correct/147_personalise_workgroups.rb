converted = 0
skipped = 0

User.includes(:workgroups).find_each do |user|
  workgroups = user.workgroups.to_a

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
    name: "Default for #{user.username.presence || user.email}",
  )

  puts "CONVERTED user=#{user.id}, workgroup=#{workgroup.id}"
  converted += 1
end

puts "Done. Converted: #{converted}, skipped: #{skipped}"