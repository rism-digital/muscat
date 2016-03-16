source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.0'

# Use mysql2 as the database for Active Record
# USE THIS VERSION for 4.1
# http://stackoverflow.com/questions/32457657/rails-4-gemloaderror-specified-mysql2-for-database-adapter-but-the-gem-i
# https://github.com/rails/rails/issues/21544
gem 'mysql2', '~> 0.3.18'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

group :development do
  gem 'web-console', '~> 2.0'
end

# For generating both digest and no digest assets
gem 'non-stupid-digest-assets'

# Papertrail for old version support
gem 'paper_trail'

# for aligning marc
gem 'needleman_wunsch_aligner'

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

gem 'activeadmin', '~> 1.0.0.pre2' #, github: 'rism-ch/activeadmin'#, ref: 'a2cd960'
gem 'active_admin_scoped_collection_actions', github: 'activeadmin-plugins/active_admin_scoped_collection_actions'

gem 'sunspot_rails', "2.2.0"#, git: 'https://github.com/sunspot/sunspot.git', ref: '9c4ec23'
gem 'sunspot_solr',  "2.2.0"
gem 'awesome_print'
gem 'progress_bar'
gem "rails3-jquery-autocomplete", github: 'rism-ch/rails3-jquery-autocomplete'
gem "cancan"
gem "rolify"
group :development do
    gem 'webrick', '~> 1.3.1'
end
gem 'blacklight', "5.14"
gem "blacklight_advanced_search"
gem 'bootstrap-sass', "3.3.4.1"
# For nice date ranges
#https://github.com/projectblacklight/blacklight_range_limit
gem "blacklight_range_limit"
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
gem 'pry', :group => :development

# Background tasks
# https://github.com/collectiveidea/delayed_job/issues/776
gem 'delayed_job', "4.1.1", github: 'rism-ch/delayed_job'
gem 'delayed_job_active_record'
gem 'progress_job', github: "rism-ch/progress_job"

# Scheduled tasks cron style
gem 'crono', github: 'plashchynski/crono'
gem 'daemons'
