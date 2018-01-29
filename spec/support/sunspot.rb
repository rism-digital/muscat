#Rough method to prevent messing up development index with rspec
# TODO transfer to some testing environment
RSpec.configure do |config|
  config.after(:suite) do
    puts "CLEANING THE INDEX....".yellow
    Sunspot.remove(Source) { with(:created_at).greater_than(5.minutes.ago)  }
    Sunspot.remove(Person) { with(:created_at).greater_than(5.minutes.ago)  }
    Sunspot.remove(Institution) { with(:created_at).greater_than(5.minutes.ago)  }
    Sunspot.remove(Catalogue) { with(:created_at).greater_than(5.minutes.ago)  }
    Sunspot.commit
    puts "READY!".green
  end
end

