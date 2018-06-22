ENV["RAILS_ENV"] = 'test'
require File.expand_path('../../config/environment', __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f  }
#silence_stream STDOUT do
#    load "#{Rails.root}/db/schema.rb"
#end
Dir[Rails.root.join('spec', 'support', 'factories', '**','*.rb')].each { |file| require(file)  } 
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.expose_dsl_globally = true
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.include CollectionHelper
  config.include FactoryBot::Syntax::Methods
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end
  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
  config.color = true
  config.tty = true
  config.formatter = :documentation
end


