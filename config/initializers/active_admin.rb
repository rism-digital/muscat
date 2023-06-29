# coding: utf-8
# Customize the ActiveAdmin header to add our own item. NOTE: This class
# must be registered as the view factory for the header. See below, in the
# setup block.
class MuscatAdminHeader < ActiveAdmin::Views::Header
  include Rails.application.routes.url_helpers

  def build(namespace, menu)
    # Create a new menu item and add it to the menu. By default, all menu
    # items have priority 10, and they're sorted within the priority. Setting
    # this item's priority to 11 ensures that it appears after the other
    # menu items (except for "Live Site"), which is what we want.
    #
    # See lib/active_admin/dashboards.rb in the activeadmin gem, for
    # example.
    
    # Now, invoke the parent class's build method to put it all together.
    #if can? :manage, User
    super(namespace, menu) unless is_selection_mode?
  end
end

require 'active_admin_record_type_filter'
require 'active_admin_lib_siglum_filter'

ActiveAdmin.setup do |config|

  # == Site Title
  #
  # Set the title that is displayed on the main layout
  # for each of the active admin pages.
  #
  config.site_title = "Muscat"
  # Set the link url for the title. For example, to take
  # users to your main site. Defaults to no link.
  #
  # config.site_title_link = "/"

  # Set an optional image to be displayed for the header
  # instead of a string (overrides :site_title)
  #
  # Note: Aim for an image that's 21px high so it fits in the header.
  #
  config.site_title_image = "logo3-#{RISM::SITE_ID}.png"

  # == Default Namespace
  #
  # Set the default namespace each administration resource
  # will be added to.
  #
  # eg:
  #   config.default_namespace = :hello_world
  #
  # This will create resources in the HelloWorld module and
  # will namespace routes to /hello_world/*
  #
  # To set no namespace by default, use:
  #config.default_namespace = false
  
  #
  # Default:
  # config.default_namespace = :admin
  #
  # You can customize the settings for each namespace by using
  # a namespace block. For example, to change the site title
  # within a namespace:
  #
  #   config.namespace :admin do |admin|
  #     admin.site_title = "Custom Admin Title"
  #   end
  #
  # This will ONLY change the title for the admin section. Other
  # namespaces will continue to use the main "site_title" configuration.

  # == User Authentication
  #
  # Active Admin will automatically call an authentication
  # method in a before filter of all controller actions to
  # ensure that there is a currently logged in admin user.
  #
  # This setting changes the method which Active Admin calls
  # within the controller.
  config.authentication_method = :authenticate_user!

  # == User Authorization
  #
  # Active Admin will automatically call an authorization
  # method in a before filter of all controller actions to
  # ensure that there is a user with proper rights. You can use
  # CanCanAdapter or make your own. Please refer to documentation.
  config.authorization_adapter = ActiveAdmin::CanCanAdapter

  # You can customize your CanCan Ability class name here.
  # config.cancan_ability_class = "Ability"

  # You can specify a method to be called on unauthorized access.
  # This is necessary in order to prevent a redirect loop which happens
  # because, by default, user gets redirected to Dashboard. If user
  # doesn't have access to Dashboard, he'll end up in a redirect loop.
  # Method provided here should be defined in application_controller.rb.
  # config.on_unauthorized_access = :access_denied

  # == Current User
  #
  # Active Admin will associate actions with the current
  # user performing them.
  #
  # This setting changes the method which Active Admin calls
  # to return the currently logged in user.
  config.current_user_method = :current_user


  # == Logging Out
  #
  # Active Admin displays a logout link on each screen. These
  # settings configure the location and method used for the link.
  #
  # This setting changes the path where the link points to. If it's
  # a string, the strings is used as the path. If it's a Symbol, we
  # will call the method to return the path.
  #
  # Default:
  config.logout_link_path = :destroy_user_session_path

  # This setting changes the http method used when rendering the
  # link. For example :get, :delete, :put, etc..
  #
  # Default:
  # config.logout_link_method = :get


  # == Root
  #
  # Set the action to call for the root path. You can set different
  # roots for each namespace.
  #
  # Default:
  config.root_to = 'dashboard#index'
  #config.root_to = 'sources#index'


  # == Admin Comments
  #
  # This allows your users to comment on any resource registered with Active Admin.
  #
  # You can completely disable comments:
  config.comments = true
  #
  # You can disable the menu item for the comments index page:
  # Menus set by hand for translation, see below
  config.comments_menu = false
  #
  # You can change the name under which comments are registered:
  #config.comments_registration_name = 'AdminComment'


  # == Batch Actions
  #
  # Enable and disable Batch Actions
  #
  config.batch_actions = true


  # == Controller Filters
  #
  # You can add before, after and around filters to all of your
  # Active Admin resources and pages from here.
  #
  # config.before_action :do_something_awesome
  
  # LP - for caching filters, pagination and order
  config.before_action :restore_search_filters
  config.after_action :save_search_filters
  
  
  # == Setting a Favicon
  #
  # config.favicon = '/assets/favicon.ico'


  # == Removing Breadcrumbs
  #
  # Breadcrumbs are enabled by default. You can customize them for individual
  # resources or you can disable them globally from here.
  #
  # config.breadcrumb = false


  # == Register Stylesheets & Javascripts
  #
  # We recommend using the built in Active Admin layout and loading
  # up your own stylesheets / javascripts to customize the look
  # and feel.
  #
  # To load a stylesheet:
  #   config.register_stylesheet 'my_stylesheet.css'
  #
  # You can provide an options hash for more control, which is passed along to stylesheet_link_tag():
  #   config.register_stylesheet 'my_print_stylesheet.css', :media => :print
  #
  # To load a javascript file:
  #   config.register_javascript 'my_javascript.js'
  config.register_stylesheet 'jquery-ui.css'
  #config.register_javascript 'marc_editor.js'
  #config.register_javascript 'marc_json.js'
  #config.register_javascript 'jquery.blockUI.js'
  #config.register_javascript 'jquery.cascade.js'
  #config.register_javascript 'jquery.dirtyFields.js'
  #config.register_javascript 'jquery.maskedinput.js'
  #config.register_javascript 'jquery.validate.js'

  config.register_stylesheet 'muscat-print.css', :media => :print
  config.register_stylesheet 'diva.min.css'

  # == CSV options
  #
  # Set the CSV builder separator
  # config.csv_options = { :col_sep => ';' }
  #
  # Force the use of quotes
  # config.csv_options = { :force_quotes => true }


  # == Menu System
  #
  # You can add a navigation menu to be used in your application, or configure a provided menu
  #
  # To change the default utility navigation to show a link to your website & a logout btn
  #
  #   config.namespace :admin do |admin|
  #     admin.build_menu :utility_navigation do |menu|
  #       menu.add label: "My Great Website", url: "http://www.mygreatwebsite.com", html_options: { target: :blank }
  #       admin.add_logout_button_to_menu menu
  #     end
  #   end
  #
  # If you wanted to add a static menu item to the default menu provided:
  #
  #   config.namespace :admin do |admin|
  #     admin.build_menu :default do |menu|
  #       menu.add label: "My Great Website", url: "http://www.mygreatwebsite.com", html_options: { target: :blank }
  #     end
  #   end
  # UNDOCUMENTED! UNDOCUMENTED!
  # SInce we do not use default namespace
  # we need to use :root instead of :admin
  # BTW going back to admin ns we put again :admin
  config.namespace :admin do |admin|
    admin.build_menu :default do |menu|
      menu.add :label => proc {I18n.t(:menu_administration)}, id: 'admin_menu', :priority => 1
      menu.add  :label => proc {I18n.t(:menu_languages)}, id: 'lang_menu', :priority => 2 do |lang|
        lang.add :label => "DE", :url => proc { url_for(:locale => 'de') }, id: 'i18n-de', :priority => 1, :html_options   => {:style => 'float:left;'}
        lang.add :label => "EN", :url => proc { url_for(:locale => 'en') }, id: 'i18n-en', :priority => 2, :html_options   => {:style => 'float:left;'}
        lang.add :label => "ES", :url => proc { url_for(:locale => 'es') }, id: 'i18n-es', :priority => 3, :html_options   => {:style => 'float:left;'}
        lang.add :label => "FR", :url => proc { url_for(:locale => 'fr') }, id: 'i18n-fr', :priority => 4, :html_options   => {:style => 'float:left;'}
        lang.add :label => "IT", :url => proc { url_for(:locale => 'it') }, id: 'i18n-it', :priority => 5, :html_options   => {:style => 'float:left;'}
        lang.add :label => "PL", :url => proc { url_for(:locale => 'pl') }, id: 'i18n-pl', :priority => 6, :html_options   => {:style => 'float:left;'}
        lang.add :label => "PT", :url => proc { url_for(:locale => 'pt') }, id: 'i18n-pt', :priority => 7, :html_options   => {:style => 'float:left;'}
        lang.add :label => "CA", :url => proc { url_for(:locale => 'ca') }, id: 'i18n-ca', :priority => 8, :html_options   => {:style => 'float:left;'}      
      end
      # Add the menu by hand because otherwise it is not getting translated
      menu.add :label => proc {I18n.t(:menu_comments)}, id: 'comments_menu', :priority => 4, :url => "/admin/comments"
      menu.add :label => proc {I18n.t(:menu_catalog)}, id: 'catalog_menu', :priority => 8, :url => "/catalog"
      menu.add :label => proc {I18n.t(:menu_indexes)}, id: 'indexes_menu', :priority => 20
    end
    
    admin.build_menu :utility_navigation do |menu|
      admin.add_current_user_to_menu menu
      admin.add_logout_button_to_menu menu
    end
    
  end

  # == Download Links
  #
  # You can disable download links on resource listing pages,
  # or customize the formats shown per namespace/globally
  #
  # To disable/customize for the :admin namespace:
  #
  #   config.namespace :admin do |admin|
  #
  #     # Disable the links entirely
  #     admin.download_links = false
  #
  #     # Only show XML & PDF options
  #     admin.download_links = [:xml, :pdf]
  #
  #     # Enable/disable the links based on block
  #     #   (for example, with cancan)
  #     admin.download_links = proc { can?(:view_download_links) }
  #
  #   end


  # == Pagination
  #
  # Pagination is enabled by default for all resources.
  # You can control the default per page count for all resources here.
  #
  # config.default_per_page = 30


  # == Filters
  #
  # By default the index screen includes a “Filters” sidebar on the right
  # hand side with a filter for each attribute of the registered model.
  # You can enable or disable them for all resources here.
  #
  # config.filters = true
  
  
  config.view_factory.header = MuscatAdminHeader
end

# LP - added for caching filters, pagination and order
require 'active_admin/filter_saver/controller'
# LP - added for forcing kaminari to always include page param (necessary for FilterSaver)
require "kaminari/helpers/tag"
 
## RZ This monkey patch enables some filter labels to be translated in the Search Status
## sidebar.
require 'active_admin/filter_label'
## RZ Let the download links disappear BUT have the .xml download for a single item
require 'active_admin/download_links'
## RZ Add some text to the comments box, for help
require 'active_admin/active_admin_comments'

ActiveAdmin.before_load do |app|
  # Add our Extensions
  ActiveAdmin::BaseController.send :include, ActiveAdmin::FilterSaver::Controller
end
