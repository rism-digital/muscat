Devise::SamlSessionsController.class_eval do
  after_action :store_winning_strategy, only: :create

  private

  def store_winning_strategy
    warden.session(:user)[:strategy] = warden.winning_strategies[:user].class.name.demodulize.underscore.to_sym
  end
end
