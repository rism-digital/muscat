require "rails_helper"

RSpec.describe User, type: :model do
  %w[encrypted_password reset_password_token invitation_token current_sign_in_ip failed_attempts].each do |attribute|
    it "rejects direct and associated filters on #{attribute}" do
      expect(described_class.ransack("#{attribute}_start" => "probe").result.to_sql).not_to include("WHERE")
      expect(DigitalObject.ransack("user_#{attribute}_start" => "probe").result.to_sql).not_to include("WHERE", "JOIN")
    end
  end

  it "preserves public user filters and role/workgroup searches" do
    expect(described_class.ransack(username_or_name_or_email_cont: "cataloguer").result.to_sql).to include("WHERE", "username", "name", "email")
    expect(described_class.ransack(roles_id_in: [1]).result.to_sql).to include("JOIN", "roles")
    expect(described_class.ransack(workgroups_name_cont: "Germany").result.to_sql).to include("JOIN", "workgroups")
  end

  it "blocks traversal through user invitations" do
    expect(DigitalObject.ransack(user_invited_by_of_User_type_encrypted_password_start: "probe").result.to_sql).not_to include("WHERE", "JOIN")
  end
end
