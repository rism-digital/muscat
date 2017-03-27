Dir["#{Rails.root}/lib/statistics/*.rb"].each do |file|
  require file 
end
