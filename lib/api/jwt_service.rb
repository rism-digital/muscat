class JwtService
  def self.encode(payload:)
    JWT.encode(payload, self.secret)
  end

  def self.decode(token:)
    JWT.decode(token, self.secret).first
  end

  def self.secret
    Rails.application.secrets.secret_key_base
  end
end
