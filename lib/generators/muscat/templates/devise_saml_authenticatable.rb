
Devise::SamlSessionsController.class_eval do
  after_action :store_winning_strategy, only: :create

  private

  def store_winning_strategy
    warden.session(:user)[:strategy] = warden.winning_strategies[:user].class.name.demodulize.underscore.to_sym
  end
end

Devise.saml_update_resource_hook= Proc.new do |user, saml_response, auth_value|
  user.user_create_strategy= :saml_authenticatable
  user.roles << Role.find_by(name: RISM::SAML_AUTHENTICATION_CREATE_USER_ROLE)
  Devise.saml_default_update_resource_hook.call(user, saml_response, auth_value)
end

Devise.setup do |config|
  # ==> Configuration for :saml_authenticatable

  # Create user if the user does not exist. (Default is false)
  config.saml_create_user = true

  # Update the attributes of the user after a successful login. (Default is false)
  config.saml_update_user = true

  # Set the default user key. The user will be looked up by this key. Make
  # sure that the Authentication Response includes the attribute.
  config.saml_default_user_key = :email

  # Optional. This stores the session index defined by the IDP during login.  If provided it will be used as a salt
  # for the user's session to facilitate an IDP initiated logout request.
  config.saml_session_index_key = :session_index

  # You can set this value to use Subject or SAML assertation as info to which email will be compared.
  # If you don't set it then email will be extracted from SAML assertation attributes.
  # config.saml_use_subject = true

  # You can support multiple IdPs by setting this value to the name of a class that implements a ::settings method
  # which takes an IdP entity id as an argument and returns a hash of idp settings for the corresponding IdP.
  # config.idp_settings_adapter = "MyIdPSettingsAdapter"

  # You provide you own method to find the idp_entity_id in a SAML message in the case of multiple IdPs
  # by setting this to the name of a custom reader class, or use the default.
  # config.idp_entity_id_reader = "DeviseSamlAuthenticatable::DefaultIdpEntityIdReader"

  # You can set a handler object that takes the response for a failed SAML request and the strategy,
  # and implements a #handle method. This method can then redirect the user, return error messages, etc.
  # config.saml_failed_callback = nil

  # You can customize the named routes generated in case of named route collisions with
  # other Devise modules or libraries. Set the saml_route_helper_prefix to a string that will
  # be appended to the named route.
  # If saml_route_helper_prefix = 'saml' then the new_user_session route becomes new_saml_user_session
  config.saml_route_helper_prefix = 'saml'

  # You can add allowance for clock drift between the sp and idp.
  # This is a time in seconds.
  # config.allowed_clock_drift_in_seconds = 0

  # idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
  # config.saml_config= idp_metadata_parser.parse_remote "https://remote-sso-server.example.org/saml/idp/metadata"
  # Configure with your SAML settings (see ruby-saml's README for more information: https://github.com/onelogin/ruby-saml).
  config.saml_configure do |settings|
    # assertion_consumer_service_url is required starting with ruby-saml 1.4.3: https://github.com/onelogin/ruby-saml#updating-from-142-to-143
    settings.assertion_consumer_service_url     = "https://local-muscat-server.example.org/admin/saml/auth"
    settings.assertion_consumer_service_binding = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
    settings.name_identifier_format             = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient"
    # settings.authn_context                      = ""
    # settings.idp_slo_service_url                = "https://remote-sso-server.example.org/simplesaml/www/saml2/idp/SingleLogoutService.php"
    settings.idp_sso_service_url                = "https://remote-sso-server.example.org/test/saml/idp/auth"
    # settings.idp_cert_fingerprint               = "9E:65:2E:03:06:8D:80:F2:86:C7:6C:77:A1:D9:14:97:0A:4D:F4:4D"
    # settings.idp_cert_fingerprint_algorithm     = "http://www.w3.org/2000/09/xmldsig#sha1"
    # settings.sp_entity_id                       = "https://remote-sso-server.example.org/admin/saml/metadata"
    # settings.compress_request                   = false
  end
end
