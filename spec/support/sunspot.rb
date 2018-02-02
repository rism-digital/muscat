#$original_sunspot_session = Sunspot.session

#RSpec.configure do |config|
#  config.before do
#    Sunspot.session = Sunspot::Rails::StubSessionProxy.new($original_sunspot_session)
#  end
#
#  config.before :each, :solr => true do
#    Sunspot::Rails::Tester.start_original_sunspot_session
#    Sunspot.session = $original_sunspot_session
#    Sunspot.remove_all!
#  end
#end



##Rough method to prevent messing up development index with rspec
## TODO transfer to some testing environment
RSpec.configure do |config|
  #config.before(:all) do
  #  %x( rake sunspot:solr:start )
  #end

  #config.after(:all) do
  #  %x( rake sunspot:solr:stop )

  #end
#  config.after(:suite) do
##    puts "CLEANING THE INDEX....".yellow
##    Sunspot.remove(Source) { with(:created_at).greater_than(5.minutes.ago)  }
##    Sunspot.remove(Person) { with(:created_at).greater_than(5.minutes.ago)  }
##    Sunspot.remove(Institution) { with(:created_at).greater_than(5.minutes.ago)  }
##    Sunspot.remove(Catalogue) { with(:created_at).greater_than(5.minutes.ago)  }
##    Sunspot.commit
##    puts "READY!".green
#  end
end
#
