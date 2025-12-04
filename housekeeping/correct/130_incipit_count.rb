range = Time.zone.now.all_month

range = Time.zone.parse("2025-10-01").all_month   # specific month
#range = Time.zone.parse("2025-01-01").all_year    # specific year

by_day = Source.where(created_at: range)
               .select(:id, :created_at)
               .order(:created_at)
               .group_by { |s| s.created_at.to_date }
               .transform_values { |sources| sources.map(&:id) }

megatot = 0
by_day.each do |day_src|
  day_tot = 0
  day_src[1].each do |sid|
    s = Source.find(sid)
    day_tot += s.marc["031"].count
  end

  megatot += day_tot
end

puts megatot
puts megatot / by_day.count