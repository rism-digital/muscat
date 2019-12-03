class TranslationController < ActionController::API
  
  #before_action :authenticate_user!
  
  def show
    t1 = Translation.new("en")
    if params[:lang]
      t2 = Translation.new(params[:lang])
      render json: Translation.combine(t1, t2)
    else
      t2, t3, t4, t5 = Translation.new("de"),  Translation.new("fr"),  Translation.new("it"),  Translation.new("es") 
      render json: Translation.combine(t1, t2, t3, t4, t5)
    end
  end

  def update
    translation = Translation.new(params[:lang])
    render json: translation.update(params[:code], params[:value])
  end

end

