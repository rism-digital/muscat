require 'rails_helper'

RSpec.describe "Sign in", type: :feature do

  describe "whith only database_authenticatable" do
    let!(:editor) { create(:editor) }

    before do
      RISM::AUTHENTICATION_METHODS = :database_authenticatable
      visit new_user_session_path
      fill_in_login_form_and_submit
    end

    def fill_in_login_form_and_submit
      expect(page).to have_content("Muscat Login")

      within ".inputs" do
        fill_in "user[email]", with: editor.email
        fill_in "user[password]", with: password
      end
      within ".actions" do
        find("*[type=submit]").click
      end      
    end

    context "with user's password" do
      let(:password) { "P4ssword" }

      it "signs in successfully" do
        within ".flash" do
          expect(page).to have_content("Signed in successfully.")
        end
      end
    end

    context "with different password" do
      let(:password) { "different_Password123" }

      it "refuses to sign in" do
        within ".flash" do
          expect(page).to have_content("Invalid email or password.")
        end
      end
    end
  end


end
