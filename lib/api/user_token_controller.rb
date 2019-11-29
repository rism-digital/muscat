class UserTokenController < ActionController::Base

  def create
    user = User.find_by_email(params[:user][:email])
    if user.valid_password?(params[:user][:password])
      jwt = JwtService.encode(payload: {"sub" => user.id})
      render json: {jwt: jwt}
    else
      render json: {status: "Not authorized!"}
    end

  end
end
