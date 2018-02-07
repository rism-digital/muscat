RSpec.configure do |config|
  config.after(:each) do
    unless Sunspot.search(Source).hits.empty?
      Sunspot.remove_all!(Source)
    end
 end
end
