class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout 'blacklight'

  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'blacklight'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_user_location!, if: :storable_location?
  before_action :set_locale, :set_paper_trail_whodunnit, :auth_user, :prepare_exception_notifier, :test_version_warning, :test_muscat_reindexing

  # see https://github.com/heartcombo/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr? 
  end

  def store_user_location!
    # :user is the scope we are authenticating
    store_location_for(:user, request.fullpath)
  end

  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || super
  end

  def prepare_exception_notifier
    if current_user
      request.env["exception_notifier.exception_data"] = {:current_user => current_user } 
    else
      request.env["exception_notifier.exception_data"] = {:current_user => "Not Logged In" } 
    end
  end

  def auth_user
    redirect_to "/admin/login" unless (user_signed_in? || RISM::ANONYMOUS_NAVIGATION || request.path == "/admin/login" || (defined?(saml_user_signed_in?) && saml_user_signed_in?))
  end
  
  def test_version_warning
    return if (RISM::TEST_SERVER == false)
    if action_name && ["new", "destroy", "edit", "marc_editor_save"].include?(action_name)
      flash[:warning] = "You are operating on a test server and changes will be overwritten."
    end
  end

  def test_muscat_reindexing
    flash[:notice] = "Muscat in reindexing, search results may be incomplete" if ::MuscatProcess.is_reindexing?
  end

  # Code for rescueing lock conflicts errors
  rescue_from ActiveRecord::StaleObjectError do |exception|
     respond_to do |format|
        format.html {
          flash.now[:error] = "Another user has made a change to that record " +
             "since you accessed the edit form."
          render :edit
       }
       format.json { head :conflict }
    end
  end
  	
  def user_for_paper_trail
   current_user.try :name
  end
  
  def is_selection_mode?
    return params && params[:select].present?
  end

  def is_folder_selected?
    return params && params[:q].present? && params[:q][:id_with_integer].present? && params[:q][:id_with_integer].include?("folder_id:")
  end

  def get_folder_from_params
    t = params[:q][:id_with_integer].split(":")
    t.count < 2 ? nil : t[1]
  end

  def get_filter_record_type
    if params.include?(:q) && params[:q].include?("record_type_with_integer")
      params[:q]["record_type_with_integer"]
    end
  end

  private

  def user_activity
      current_user.try :touch
  end

  # Find out and set the locale, store into a cookie
  def set_locale 
    # We do not check if the locale is available. The list is actually set in the
    # menu (see active_admin.rb) 
    if params[:locale] ## && AVAILABLE_LOCALES.include?(params[:locale])
    # user is changing locale, keep it for the session and in a cookie
      session[:locale] = params[:locale]
      cookies[:locale] = { :value => session[:locale], :expires => 30.days.from_now }
    elsif !session[:locale]
      # no locale for the session yet, use cookie or http_header (or default)
      if (cookies[:locale]) # && AVAILABLE_LOCALES.include?(cookies[:locale])
        session[:locale] = cookies[:locale] 
      else
        #logger.debug "HTTP_ACCEPT_LANGUAGE:#{request.env['HTTP_ACCEPT_LANGUAGE']}" 
        session[:locale] = _locale_from_http_header
        cookies[:locale] = { :value => session[:locale], :expires => 30.days.from_now }
      end
    end
    
    #logger.debug "LOCALE", I18n.locale
    I18n.locale = session[:locale]
  end 
  
  def configure_permitted_parameters
    added_attrs = [:username, :email, :password, :password_confirmation, :remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :sign_in, keys: [:login, :password]
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end

  def restore_search_filters  
  end
  
  def save_search_filters  
  end
  
  private
  
  # Parse the http header to get a locale
  # Hard-coded list - to be improved
  def _locale_from_http_header 
    return "en" if !request.env || !request.env.include?('HTTP_ACCEPT_LANGUAGE')
    locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first 
    return locale if ["en", "fr", "it", "de", "es", "pt"].include?(locale)
    "en"
  end 

end
