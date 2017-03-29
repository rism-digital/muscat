ENV['RAILS_ENV'] ||= 'development'
require 'spec_helper'
require 'rspec/rails'
require 'capybara/rspec'


RSpec.configure do |config|
  config.include Rails.application.routes.url_helpers
  config.use_transactional_fixtures = true
  config.include Devise::TestHelpers, :type => :controller
  config.infer_spec_type_from_file_location!
  config.include Warden::Test::Helpers
  config.include Capybara::DSL
  config.filter_rails_from_backtrace!
end
