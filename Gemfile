source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.1'

# Use mysql2 as the database for Active Record
gem 'mysql2'

# Use SCSS for stylesheets
gem 'sassc-rails'#, '~> 6.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'#, '~> 4.2'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails'#, '~> 5.0'

# NOTE HERE: since execjs 2.8, the therubyracer is deprecated
# Mini racer 0.4 appears to be broken.
# A runtime can be used with node.js: apt-get install nodejs
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails', "~> 4.5"
gem 'jquery-ui-rails', '~> 6.0'
gem 'js_cookie_rails', '~> 2.2.0'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.2.1'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.12'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end


# Papertrail for old version support
gem 'paper_trail'

# for aligning marc
gem 'needleman_wunsch_aligner', "1.0.4"

# for the documentation
gem 'htmlentities', '~> 4.3.4'

# Use debugger
# gem 'debugger', group: [:development, :test

gem 'activeadmin'
# Disabled - left to find it again
#gem 'active_admin_scoped_collection_actions', git: 'https://github.com/activeadmin-plugins/active_admin_scoped_collection_actions'

gem 'sunspot_rails', '~> 2.7'
#gem 'sunspot_solr'
gem 'awesome_print'
gem 'progress_bar', '1.0.6', git: 'https://github.com/rism-ch/progress_bar'

gem "rails3-jquery-autocomplete", '~> 1.0.26', git: 'https://github.com/rism-ch/rails3-jquery-autocomplete'
gem "cancancan"
gem "rolify"

group :development do
    gem 'puma'
end

gem 'devise'
gem 'devise-i18n'
#gem 'devise_saml_authenticatable', require: false

# paperclip for image storage
gem "kt-paperclip"#, "~> 6.2.0"

# https://github.com/zdennis/activerecord-import/wiki
# For bulk import SQL data
gem 'activerecord-import'

# Uncomment this to test the webpage saving
# in housekeeping/selenium_webdriver
# gem 'selenium-webdriver'

gem 'ruby-prof'
group :development, :test do
  gem 'pry'
end

# Background tasks
# https://github.com/collectiveidea/delayed_job/issues/776
gem 'delayed_job', '~> 4.1', git: 'https://github.com/rism-ch/delayed_job'
gem 'delayed_job_active_record'#, '4.1.4'
gem 'progress_job', '0.0.4', git: "https://github.com/rism-ch/progress_job"

# used to run delayed_job in bg
gem 'daemons'

# Add I18n in js
gem "i18n-js", '~> 3.4'
gem 'colorize'

gem 'exception_notification'
gem 'cql-ruby', '0.9.1', :git => 'https://github.com/jrochkind/cql-ruby'
gem 'chart-js-rails'

gem 'iiif-presentation'

## Add translations for activerecord and co
gem 'rails-i18n'

gem 'gruff'

# These need to be loaded in production too
gem 'solr_wrapper'#, '>= 0.3'
#gem 'ruby-saml-idp'

gem 'rsolr'#, '>= 1.0'

## For better parallel processing
gem 'parallel'

gem 'rubyzip'

# To render markdown
gem 'redcarpet'
# For parsing rism
gem 'reverse_markdown'
gem 'kramdown'
gem 'whatlanguage'

# To make links clickable in the Comments
gem "anchored"

# Avoid TypeError: superclass mismatch for class Command
# See https://github.com/erikhuda/thor/issues/721
gem 'thor'

group :test do
  gem "rspec"
  gem 'rspec-rails', '~> 3.5'
  gem 'factory_bot_rails'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem 'generator_spec'
  # Use sqlite3 for testing db
  gem 'sqlite3'
end

# This gem is used in subfield_select_codes
# for a crude sorting of unicode chars
# See views_helper.rb for the actual call
# in local_sort()
gem 'sort_alphabetical'

gem 'differ'

gem 'rodf' # write ODS
gem "roo" # read ODS

gem 'tty-spinner'
gem 'libxml-ruby'

# For stand-alone installations
gem 'passenger'

gem 'listen'

# Uncomment this if you want to test emails in development
#gem 'mailcatcher'
#gem "string-similarity"
#gem "rest-client"
