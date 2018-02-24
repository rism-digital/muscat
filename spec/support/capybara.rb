require 'selenium/webdriver'
Capybara.register_driver :chrome do |app|
   capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
     chromeOptions: {
       args: %w[ no-sandbox headless disable-popup-blocking disable-gpu window-size=1280,1024]
     }
   )
 
   Capybara::Selenium::Driver.new(app, browser: :chrome, desired_capabilities: capabilities)
 end
 
 Capybara.javascript_driver = :chrome
=begin
IS_DEBUG_MODE = -> { ENV['DEBUG'].present? ? :chrome : :headless_chrome  }

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new
  options.add_argument 'headless'
  Capybara::Selenium::Driver.new app, browser: :chrome, options: options
end

Capybara.configure do |config|
  config.default_max_wait_time = 30
  config.default_driver = IS_DEBUG_MODE.call
  config.javascript_driver = IS_DEBUG_MODE.call
end
=end
