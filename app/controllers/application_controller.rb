class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
   include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on 
  # these methods in order to perform user specific actions. 

  layout 'blacklight'

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter :set_locale
  
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
    return locale if ["en", "fr", "it", "de"].include?(locale)
    "en"
  end 

end
