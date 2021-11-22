# frozen_string_literal: true

module Muscat
  # To run this generator :saml_authenticatable must still NOT be included in RISM::AUTHENTICATION_METHODS
  # otherwise "Invalid route name, already in use: 'new_user_session'" ArgumentError is raised.
  #
  # To run this generator: `bin/rails g muscat:install_saml`.
  #
  # Read the INSTALL.rdoc for configuration.
  #
  class InstallSamlGenerator < Rails::Generators::Base
    desc "Installs saml_authenticatable required files"

    source_root File.expand_path("templates", __dir__)

    def copy_devise_login_form
      copy_file "activeadmin_devise_sessions_new.html.erb", "app/views/active_admin/devise/sessions/new.html.erb"
    end

    def copy_initializer
      copy_file "devise_saml_authenticatable.rb", "config/initializers/devise_saml_authenticatable.rb"
    end

    def copy_attribute_map
      copy_file "attribute-map.yml", "config/attribute-map.yml"
    end
  end
end
