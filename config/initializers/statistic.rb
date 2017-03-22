Dir["#{Rails.root}/lib/statistic/*.rb"].each do |file|
  require file 
end
