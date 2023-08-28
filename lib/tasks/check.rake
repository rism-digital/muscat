namespace :check do
  desc "Start the rspec"
  task start: :environment do
    sh %{ bundle exec rspec -fd --format html --out public/report.html }
  end

end
