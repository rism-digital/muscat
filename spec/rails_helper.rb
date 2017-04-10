ENV['RAILS_ENV'] ||= 'development'
require File.expand_path('../../config/environment', __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f  }
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = true
  config.include Devise::TestHelpers, :type => :controller
  #config.include DeviseRequestSpecHelpers
  config.include FactoryGirl::Syntax::Methods
  config.infer_spec_type_from_file_location!
  config.include Warden::Test::Helpers
  config.include Capybara::DSL
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  #config.include RequestSpecHelper, type: :request
end
