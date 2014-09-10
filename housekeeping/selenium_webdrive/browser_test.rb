# Need to uncomment selenium Gem in Gemfile
# Works with Firefox
require 'rubygems'
require 'selenium-webdriver'

driver = Selenium::WebDriver.for :firefox
driver.get "http://localhost:3000/"

element = driver.find_element :name => "user[email]"
element.send_keys "admin@example.com"

element = driver.find_element :name => "user[password]"
element.send_keys "password"

element.submit

File.open("selenium.log", 'w') do |logfile|

  Source.all.each do |m|

    begin
      driver.get "http://localhost:3000/sources/#{m.id}/edit"

      puts "Page title is #{driver.title}"
      logfile.write "Page title is #{driver.title}"

      element = driver.find_element :class => "marc_save_btn"
      element.click
  
      # wait for a specific element to show up
      wait = Selenium::WebDriver::Wait.new(:timeout => 10) # seconds
      wait.until do 
        driver.execute_script("return jQuery.active") == 0 ? true : false
      end
    rescue
      puts "#{m.id} failed in selenium"
      logfile.write "ERROR - #{m.id} failed in selenium"
    end
  
  end
end

driver.quit