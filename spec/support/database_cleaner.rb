RSpec.configure do |config|

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, { pre_count: true, reset_ids: true  })
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :feature) do
    driver_shares_db_connection_with_specs = Capybara.current_driver == :rack_test
    unless driver_shares_db_connection_with_specs
      DatabaseCleaner.strategy = :truncation
    end
  end

#  config.before(:each, :js => true) do
#    #DatabaseCleaner.strategy = :transaction
#    #DatabaseCleaner.strategy = :deletion
#    DatabaseCleaner.strategy = :truncation
#  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end

