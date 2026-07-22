module Users
  class InvitationsController < Devise::InvitationsController
    prepend_before_action :sign_out_existing_user, only: [:edit, :update]
    before_action :disable_direct_invitations, only: [:new, :create]

    private

    # Users are invited from ActiveAdmin, where an administrator also assigns
    # their role and workgroups. Do not expose Devise Invitable's generic form.
    def disable_direct_invitations
      head :not_found
    end

    # Devise refuses to show invitation acceptance while a user is already
    # authenticated. This can happen when the invitation is opened in a
    # browser that still has another Muscat session, causing a redirect loop.
    def sign_out_existing_user
      return unless user_signed_in?

      sign_out(:user)
      stored_location_for(:user)
    end
  end
end
