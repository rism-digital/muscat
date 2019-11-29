Dir["#{Rails.root}/lib/statistics/*.rb"].each do |file|
  require file 
end
Dir["#{Rails.root}/lib/api/*.rb"].each do |file|
  require file 
end
