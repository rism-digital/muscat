source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '>= 5.1', '< 5.2'

# Use mysql2 as the database for Active Record
# USE THIS VERSION for 4.1
# http://stackoverflow.com/questions/32457657/rails-4-gemloaderror-specified-mysql2-for-database-adapter-but-the-gem-i
# https://github.com/rails/rails/issues/21544
gem 'mysql2'

# Use SCSS for stylesheets
gem 'sass-rails'#, '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'#, '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'#, '~> 4.2'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
#gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'#, '~> 6.0'
gem 'js_cookie_rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'#, '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

#group :development do
#  gem 'web-console', '~> 2.0'
	#gem 'rb-readline'
#end

# For generating both digest and no digest assets
gem 'non-stupid-digest-assets'

# Papertrail for old version support
gem 'paper_trail'

# for aligning marc
gem 'needleman_wunsch_aligner', "1.0.4"

# for the documentation
gem 'htmlentities'

# Use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test

gem 'activeadmin', '~> 1.2' #, git: 'https://github.com/rism-ch/activeadmin'#, ref: 'a2cd960'
# Disabled - left to find it again
#gem 'active_admin_scoped_collection_actions', git: 'https://github.com/activeadmin-plugins/active_admin_scoped_collection_actions'

gem 'sunspot_rails', "~> 2.2", git: 'https://github.com/rism-ch/sunspot', branch: "java9-stack"
gem 'sunspot_solr', "~> 2.2", git: 'https://github.com/rism-ch/sunspot', branch: "java9-stack"
gem 'awesome_print'
gem 'progress_bar', git: 'https://github.com/rism-ch/progress_bar'
gem "rails3-jquery-autocomplete", git: 'https://github.com/rism-ch/rails3-jquery-autocomplete'
gem "cancan"
gem "rolify"
group :development do
    gem 'puma'
end

gem 'blacklight', git: 'https://github.com/rism-ch/blacklight', branch: "release-6.x"
gem "blacklight_advanced_search"
gem 'bootstrap-sass'
# For nice date ranges
#https://github.com/projectblacklight/blacklight_range_limit
gem "blacklight_range_limit", git: 'https://github.com/rism-ch/blacklight_range_limit', branch: "jquery3-6.3.x"
gem 'devise'
gem 'devise-i18n'

# paperclip for image storage
gem "paperclip", "~> 4.3"

# https://github.com/zdennis/activerecord-import/wiki
# For bulk import SQL data
gem 'activerecord-import', ">= 0.4.0"

# Uncomment this to test the webpage saving
# in housekeeping/selenium_webdriver
# gem 'selenium-webdriver'

gem 'ruby-prof'
group :development, :test do
  gem 'pry'
end

# Background tasks
# https://github.com/collectiveidea/delayed_job/issues/776
gem 'delayed_job', git: 'https://github.com/rism-ch/delayed_job'
gem 'delayed_job_active_record'
gem 'progress_job', git: "https://github.com/rism-ch/progress_job"

# Scheduled tasks cron style
gem 'crono', git: 'https://github.com/plashchynski/crono'
gem 'daemons'

# Add I18n in js
gem "i18n-js", ">= 3.0.0.rc11"
gem 'colorize'

gem 'exception_notification'
gem 'cql-ruby', '0.9.1', :git => 'https://github.com/jrochkind/cql-ruby'
gem 'chart-js-rails'

gem 'osullivan'

## Add translations for activerecord and co
gem 'rails-i18n'#, github: 'svenfuchs/rails-i18n', branch: 'rails-4-x' # For 4.x

gem 'gruff'
group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
end

gem 'rsolr', '>= 1.0'

## For better parallel processing
gem 'parallel'

group :test do
  gem "rspec"
  gem 'rspec-rails', '~> 3.5'
  gem 'factory_bot_rails'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'database_cleaner'
end
