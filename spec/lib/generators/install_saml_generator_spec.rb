# frozen_string_literal: true

require "rails_helper"
require "generators/muscat/install_saml_generator"
require "generator_spec"

RSpec.describe Muscat::InstallSamlGenerator, type: :generator do
  destination Rails.root.join('tmp', 'deleteme', 'install_saml_generator')
  # arguments %w(something)

  before(:all) do
    prepare_destination
    run_generator
  end

  it "generates expected files" do
    assert_file "app/views/active_admin/devise/sessions/new.html.erb", File.open(Rails.root.join('lib', 'generators', 'muscat', 'templates', 'activeadmin_devise_sessions_new.html.erb'))
    assert_file "config/initializers/devise_saml_authenticatable.rb", File.open(Rails.root.join('lib', 'generators', 'muscat', 'templates', 'devise_saml_authenticatable.rb'))
    assert_file "config/attribute-map.yml", File.open(Rails.root.join('lib', 'generators', 'muscat', 'templates', 'attribute-map.yml'))
  end
end
