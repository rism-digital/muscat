class TranslationController < ActionController::API
  
  #before_action :authenticate_user!
  
  def show
    t = Translation.new(params[:lang])
    t.locales_from_yaml.labels_from_yaml
    render json: t.locales + t.labels
  end

end

