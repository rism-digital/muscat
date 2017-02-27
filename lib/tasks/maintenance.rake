namespace :maintenance do
  desc "Execute all scripts in maintenance folder"
  task execute: :environment do
    puts "Executing all scripts in the maintenance folder"
    scripts = Dir.glob("housekeeping/maintenance/2*.rb")
    scripts.sort.each do |script|
      system("rails runner #{Rails.root}/#{script}")
    end
  end

end
