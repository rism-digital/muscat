
# Define a dummy controller that includes the Devise test helpers,
# and override the setup hook to prevent errors in the console.
class DummyController < ApplicationController
  def self.setup(*_args); end
  include Devise::Test::ControllerHelpers
end

class ApplicationController < ActionController::Base
  # Optionally, alias the original method in case you need it:
  alias_method :devise_current_user, :current_user

  # Global override of current_user
  def current_user
    # Custom logic; for example, always use the first user
    @current_user ||= User.first
  end
end


# Instantiate the dummy controller.
controller = DummyController.new

# Create a test request.
fake_request = ActionDispatch::TestRequest.create

# Manually set both the public and internal request variables.
controller.instance_variable_set(:@_request, fake_request)
controller.instance_variable_set(:@request, fake_request)

# Set a test response.
controller.response = ActionDispatch::TestResponse.new

# Set the Devise mapping so that Devise knows which scope to use.
fake_request.env['devise.mapping'] = Devise.mappings[:user]

# Ensure that a Warden proxy is present.
fake_request.env['warden'] ||= Warden::Proxy.new(fake_request.env, Warden::Manager.new(nil))

# Use Devise's sign_in helper to sign in a user.
controller.sign_in(User.first)

# Now create a renderer that uses the controller's request environment.
renderer = ApplicationController.renderer.new(env: fake_request.env)



pb = ProgressBar.new(Source.count)
File.open("marc_recs.html", "w") do |file|
	Source.find_in_batches do |batch|

		batch.each do |s|
							
			@item = s
			@editor_profile = EditorConfiguration.get_show_layout @item
			
			#file.write(ApplicationController.renderer.render(partial: "marc/show", assigns: {editor_profile: @editor_profile, item: @item}))
      file.write(renderer.render(partial: "marc/show", assigns: {editor_profile: @editor_profile, item: @item}))
			s = nil
      pb.increment!
		end
	end
end