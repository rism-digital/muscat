require 'rails_helper'

RSpec.describe Admin::SourcesController, :type => :controller do
  describe "Source validation" do
    let(:user) { FactoryBot.create(:editor)  }
    let!(:source) { FactoryBot.create(:manuscript_source)  }
    before do
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
    end
    it "parent.id == self.id should raise validation error" do
      marc = source.marc
      new_773 = MarcNode.new(Source, "773", "", "4#")
      ip = marc.get_insert_position("773")
      new_773.add(MarcNode.new(Source, "w", "#{source.id}", nil))
      marc.root.children.insert(ip, new_773)
      source.save
      source.reload
      source.valid?
      expect(source.errors[:base].first).to eq "validates_parent_id"
    end
    it "parent.id != self.id should not raise validation error" do
      FactoryBot.create(:collection)
      marc = source.marc
      new_773 = MarcNode.new(Source, "773", "", "4#")
      ip = marc.get_insert_position("773")
      new_773.add(MarcNode.new(Source, "w", "51649", nil))
      marc.root.children.insert(ip, new_773)
      source.save
      source.reload
      source.valid?
      expect(source.errors[:base].first).to be_nil
    end

  end
end



