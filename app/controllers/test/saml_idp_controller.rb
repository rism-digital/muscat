module Test
  class SamlIdpController < SamlIdp::IdpController

    def idp_authenticate(email, password)
      true
    end

    def idp_make_saml_response(user)
      encode_SAMLResponse(params[:email])
    end

  end
end