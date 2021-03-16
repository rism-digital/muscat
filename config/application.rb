require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module RISM
  # The Marc cataloguing agency
  AGENCY = "AuArU"
  # The project letters (e.g., uk, ch)
  BASE = "default"
  # The MARC letters (used in the new_from.rhtml and in the manuscript_controller for the templates) 
  MARC = "default"
  # Select the configuration for the editor profiles to load
  EDITOR_PROFILE = ""
  # Url redirection for the deprecated Page controller (to be set only if the installation was previously in Muscat 2 with page)
  LEGACY_PAGES_URL = '/'
  # Root redirect, can be changed to something else than BL
  ROOT_REDIRECT = '/catalog'
  
  BASE_NEW_IDS = { 
    :canonic_techniques => 0,
    :catalogue        => 0,
    :holding          => 0,
    :institution      => 0,
    :liturgical_feast => 0,
    :person           => 0,
    :place            => 0,
    :source           => 1000000000,
    :standard_term    => 0,
    :standard_title   => 0,
    :work             => 0
  }
  
  # Versionning timeout for marc models
  # - if set to 0, will store a version of every save (any user)
  # - if set to -1, will not create a version for every save of the same user
  # - othervise will not save a version for a save of the same user unless the last
  #   is older than the XXX seconds - (3600 = 1 hour, 43200 = half a day)
  VERSION_TIMEOUT = 43200
  COOKIE_PRIVACY_LINK = "http://www.example.com/privacy.html?lang="
  COOKIE_PRIVACY_I18N = true
  # The project line in the header
  PROJECTLINE = "The Canons Database"
  # The strap line in the header 
  STRAPLINE = "Classifying Canonic Techniques in Early European Music"
  # The left footer
  FOOTER= "&copy; 2018 &ndash; <a href=\"http://www.arc.gov.au/\">Australian Research Council</a> <img src=\"/images/logo-arc.png\"> &ndash; <a href=\"http://www.une.edu.au/\">University of New England</a> <img src=\"/images/logo-une.jpg\"> &ndash; <a href=\"https://www.uq.edu.au/\">University of Queensland</a> <img src=\"/images/logo-uq.png\"> <br>This site enhances the MUSCAT platform by the Répertoire International des Sources Musicales. Powered by <a href=\"https://intersect.org.au/\">Intersect Australia.</a>"
  # Header menu
  MENUS = {
    :menu_admin      => :admin_root,
    :works => "/works",
    :menu_help       => "https://art-of-canon.blog/the-canons-database-help/",
    :menu_home       => :root
  }
  # Locales for Blacklight
  LOCALES = {
    :en => "English",
    :de => "Deutsch",
    :fr => "Fran&ccedil;ais",
    :it => "Italiano"
  }
  
  # Set the path for the digital object storage
  # You also need to symlink ./public/system to a system directory in it
  DIGITAL_OBJECT_PATH = "/path/to/the/digital/objects/directory"
	
	# Test server warning. Set to true to raise a flash notice waring when saving
	TEST_SERVER = false
	
	# All the comments go to this email here, set it to and address to activate
	COMMENT_EMAIL = false
	
	# Sent the validation notifications
	SEND_VALIDATION_NOTIFICATIONS = false
	# Notification email, also used for Exception Notifications
	NOTIFICATION_EMAIL = "sample@email.com"

  # Google Analytics Tracking ID
  # GOOGLE_ANALYTICS_ID = "UA-7219229-28"

  DEFAULT_EMAIL_NAME = "The Canons Database"
  DEFAULT_NOREPLY_EMAIL = "noreply@canons.org.au"
end

module Muscat
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    
    # Force validation of locales, this also silences the deprecation warning
    config.i18n.enforce_available_locales = true
    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.load_path += Dir[ (File.join(Rails.root, "config", "locales", RISM::BASE, '*.{rb,yml}'))]

    config.eager_load_paths << Rails.root.join('lib')

    config.autoload_paths << "#{Rails.root}/lib"
    config.active_job.queue_adapter = :delayed_job
    
    # config.active_record.raise_in_transactional_callbacks = true
    
  end
end

#####################################################################################################################

# Mime types for MEI files
Mime::Type.register "application/xml", :mei
# Mime types for TEI files
Mime::Type.register "application/xml", :tei
# Mime types for download of MARC records.
Mime::Type.register "application/marc", :marc
# Same as above but with txt extension.
Mime::Type.register "application/txt", :txt

