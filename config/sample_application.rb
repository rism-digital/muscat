require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module RISM
  # The project letters (e.g., uk, ch)
  BASE = "ch"
  # The MARC letters (used in the new_from.rhtml and in the manuscript_controller for the templates) 
  MARC = "ch"
  # Select the configuration for the editor profiles to load
  EDITOR_PROFILE = ""
  # Url redirection for the deprecated Page controller (to be set only if the installation was previously in Muscat 2 with page)
  LEGACY_PAGES_URL = 'http://pages'
  
  BASE_NEW_IDS = { 
    :catalogue        => 50000000,
    :institution      => 50000000,
    :liturgical_feast => 50000000,
    :person           => 50000000,
    :place            => 50000000,
    :source           => 410000000,
    :standard_term    => 50000000,
    :standard_title   => 50000000,
    :work             => 50000000
  }
  
  # Versionning timeout for marc models
  # - if set to 0, will store a version of every save (any user)
  # - if set to -1, will not create a version for every save of the same user
  # - othervise will not save a version for a save of the same user unless the last
  #   is older than the XXX seconds - (3600 = 1 hour, 43200 = half a day)
  VERSION_TIMEOUT = 43200
  
  # The project line in the header
  PROJECTLINE = "R&eacute;pertoire International des Sources Musicales"
  # The strap line in the header 
  STRAPLINE = "Schweiz - Suisse - Svizzera - Switzerland"
  # The left footer
  FOOTER= "&copy; 2015 &ndash; Verein Arbeitsstelle Schweiz des RISM<br>Hallwylstrasse 15 &ndash; Postfach 286 &ndash; CH-3000 Bern 6"
  # Header menu
  MENUS = {
    :menu_help       => "http://www.rism.info/help",
    :menu_home       => "http://www.rism.info/"
  }
  # Locales for Blacklight
  LOCALES = {
    :en => "English",
    :de => "Deutsch",
    :fr => "Fran&ccedil;ais",
    :it => "Italiano"
  }
  
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
    
    config.autoload_paths << "#{Rails.root}/lib"
  end
end


#####################################################################################################################
# Globals used for Digital Object displaying
# Tile size to be served from the iip backend - used the Digital Objects (Do*)
VIPS_TILESIZE = '256x256'
# Address of the iip server - used the Digital Objects (Do*)
TILE_SERVER = 'http://localhost/cgi-bin/iipsrv.fcgi'
# This is the backend from where to get the image information (should be same host of the webapp)
DO_HOST = 'http://localhost:3000'
# Path to where the images are stores - used the Digital Objects (Do*)
PATH_TO_PYR_IMAGES = '/path_to_pyr_images'
# Path to the vips image convertor - used the Digital Objects (Do*)
PATH_TO_VIPS = '/opt/local/bin/vips'
# Path to where retreive the ZIP files with the images to import - used the Digital Objects (Do*)
PATH_TO_UPLOADED_IMAGES = '/Users/laurent/data/in_upload'


#Globals used for incipits
INCIPIT_BINARIES = "/path_to_incipit_binaries"
# The pae2kern binary (see http://museinfo.sapp.org)
PAE2KERN = "#{INCIPIT_BINARIES}/pae2kern"
# Path to the Verovio binary, if used to generate incipits by RISM::USE_VEROVIO=true
VEROVIO = "/usr/local/bin/verovio"
# Path do the Aruspix helper data
VEROVIO_DATA = "/usr/local/share/verovio"
# Path to rsvg for converting verovio svn in png
RSVG="/usr/local/bin/rsvg"

# Path to tindex, used to index for musical incipits with Themefinder (see http://www.themefinder.org)
TINDEX = "#{INCIPIT_BINARIES}/tindex"
# Path to themax, used to search for musical incipits with Themefinder (see http://www.themefinder.org)
THEMAX = "#{INCIPIT_BINARIES}/themax"

# Path to Xalan, used for transforming a RISM MarcXML record in MEI or TEI
XALAN = "path_to"
# Path to the stylesheets used for the transformation to MEI
XSL_MEI = "#{Rails.root}/public/xsl/rism2mei-2012.xsl"
# Path to the stylesheets used for the transformation to TEI
XSL_TEI = "#{Rails.root}/public/xsl/rism2tei-2012.xsl"
# Path to the temp path used to store the incipit search queries
TINDEX_TMP_PATH = "#{Rails.root}/tmp/tindex_queries/"
# Path to the incipit query DB generated by tindex
TINDEX_PATH = "#{Rails.root}/tindex.idx"
#####################################################################################################################

# Mime types for MEI files
Mime::Type.register "application/xml", :mei
# Mime types for TEI files
Mime::Type.register "application/xml", :tei
# Mime types for download of MARC records.
Mime::Type.register "application/marc", :marc
# Same as above but with txt extension.
Mime::Type.register "application/txt", :txt

