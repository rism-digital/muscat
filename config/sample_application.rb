# coding: utf-8

require File.expand_path("../boot", __FILE__)
require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)


module RISM
  # Installation id (e.g., uk, ch, mysite). For evaluation purposes
  # just leave the default value.
  #
  # This variable is used for picking up your institution logos:
  # * public/images/logo-large-*.png (larger 130x100 logo for public pages)
  # * app/assets/images/logo3-*.png (smaller 50x40 logo for internal pages)
  # * app/assets/images/favicon.ico (you can symlink it to another name)
  # Remember to perform `rails assets:precompile` after your
  # modifications, so rails creates an optimized asset file.
  #
  # You can also use it for local customisations.  As this
  # application.rb file is plain Ruby, it may also be used to have a
  # single configuration file for different Muscat instances, where
  # the SITE_ID is used to assign the other variables in a conditional
  # (if or case) statement.
  SITE_ID = "default"

  # Site name (title, first line)
  SITE_TITLE = "Répertoire International des Sources Musicales"

  # Site additional info (subtitle, second line)
  SITE_SUBTITLE = "Schweiz - Suisse - Svizzera - Switzerland"

  # Footer left text (raw html)
  SITE_FOOTER = "<a href=\"http://www.rism.info/en/service/disclaimer.html\">Impressum</a> &ndash; &copy; 2020 &ndash; The Association <em>Internationales Quellenlexikon der Musik</em><br>Johann Wolfgang Goethe-Universität &ndash; Senckenberganlage 31-33 &ndash; D-60325 Frankfurt am Main"

  # Top right menu urls
  MENUS = {
    :menu_help => "http://www.rism.info/help",
    :menu_home => "http://www.rism.info/"
  }

  # Enabled locales for this site (by default, in the right of the page)
  LOCALES = {
    :en => "English",
    :de => "Deutsch",
    :fr => "Français",
    :it => "Italiano"
  }

  # Marc tag and subfield definition list for all record types, available
  # templates for new records, and default tags for each new record.
  # In principle you shouldn't need to modify this. Documented in
  # https://github.com/rism-ch/muscat/blob/develop/6-%20MARC_CONFIG.rdoc
  MARC = "default"

  # Marc editor layouts, display and behaviour, autocompletion and
  # validation rules. You may want to modify it if you need to add
  # other editor configurations, different from upstream.  Documented
  # in https://github.com/rism-ch/muscat/blob/develop/4-%20CONFIG.rdoc
  EDITOR_PROFILE = "default"

  # The Marc cataloguing agency. This value will go to the Marc 003 or
  # 040 tag or the records created using the Muscat editor
  AGENCY = "DE-633"

  # Url redirection for the deprecated Page controller (to be set only
  # if the installation was previously in Muscat 2 with page)
  LEGACY_PAGES_URL = "/"

  # Redirection from home site root url.  By default, the public
  # search pages (served by Blacklight, that is, /catalog)
  ROOT_REDIRECT = "/catalog"

  # Muscat has two bibliographic record types: Source and Publication.
  # Source is for unique copies found in libraries, archives or
  # museums, and strongly tied to musical manuscripts (ex., 100 tag is
  # named Composer); Publication can describe any bibliographic work,
  # and the default templates are oriented to describe academic,
  # research or secondary literature works.  If you will to use Muscat
  # as originally intended, keep "Source".  If you want to use it as
  # institutional or research repository, choose "Publication".
  # Please note that that this second choice is an ongoing work and is
  # not finished yet.
  MAIN_BIBLIOGRAPHIC_RECORD_TYPE = "Source"

  # Record ids for each records type
  BASE_NEW_IDS = {
    :publication      => 0,
    :holding          => 0,
    :institution      => 0,
    :liturgical_feast => 0,
    :person           => 0,
    :place            => 0,
    :source           => 0, # Change to 1000000000 if setting a RISM site
    :standard_term    => 0,
    :standard_title   => 0,
    :work             => 0
  }

  # Versionning timeout for marc records
  # - if set to 0, will store a version of every save (any user)
  # - if set to -1, will not create a version for every save of the same user
  # - othervise will not save a version for a save of the same user
  #   unless the last is older than the XXX seconds - (3600 = 1 hour,
  #   43200 = half a day)
  VERSION_TIMEOUT = 43200

  # Set the path for the digital object storage
  # You also need to symlink ./public/system to a system directory in it
  DIGITAL_OBJECT_PATH = "/path/to/the/digital/objects/directory"

  # Test server warning. Set to true to raise a flash notice waring when saving
  TEST_SERVER = false

  # All the comments go to this email here, set it to and address to activate
  COMMENT_EMAIL = false

  # Default "from" email
  DEFAULT_NOREPLY_EMAIL = "sample@email.com"

  # Default system name
  DEFAULT_EMAIL_NAME = "Muscat"

  # Send via email the Source record validation notifications
  SEND_VALIDATION_NOTIFICATIONS = false

  # Insert here a set of emails for people to receive notifications
  NOTIFICATION_EMAILS = ["sample@email.com"]

  # Privacy information page
  COOKIE_PRIVACY_LINK = "http://www.example.com/privacy.html?lang="

  # Append locale to privacy information page link?
  COOKIE_PRIVACY_I18N = true

  # Allow anonymous users (not signed in) to browse and search the site
  ANONYMOUS_NAVIGATION = false
end


module Muscat
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those
    # specified here.  Application configuration should go into files
    # in config/initializers -- all .rb files in that directory are
    # automatically loaded.

    # Set Time.zone default to the specified zone and make Active
    # Record auto-convert to this zone.  Run "rake -D time" for a list
    # of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # Force validation of locales, this also silences the deprecation warning
    config.i18n.enforce_available_locales = true

    # Force a default locale, other than :en
    # config.i18n.default_locale = :de
    # The default locale is :en and all translations from
    # config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.load_path += Dir[ (File.join(Rails.root, "config", "locales", 'marc_records', '*.{rb,yml}'))]
    config.autoload_paths << "#{Rails.root}/lib"
    config.eager_load_paths << Rails.root.join("lib")
    config.active_job.queue_adapter = :delayed_job
  end
end

##########################################################################

REINDEX_PIDFILE = "#{Rails.root}/tmp/pids/muscat_reindex.pid"

# Mime types for MEI files
Mime::Type.register "application/xml", :mei

# Mime types for TEI files
Mime::Type.register "application/xml", :tei

# Mime types for download of MARC records.
Mime::Type.register "application/marc", :marc
