require 'selenium/webdriver'
require 'capybara/rspec'
IS_DEBUG_MODE = -> { ENV['DEBUG'].present? ? :chrome : :headless_chrome   }

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument 'headless'
  options.add_argument 'no-sandbox'
  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

Capybara.configure do |config|
  config.default_max_wait_time = 30
  config.default_driver = IS_DEBUG_MODE.call
  config.javascript_driver = IS_DEBUG_MODE.call
end
