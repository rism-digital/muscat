require 'rails_helper'
model = :publication
RSpec.describe Admin::PublicationsController, type: :controller do
  let!(:person) { create :person }
  let!(:resource) { create model }
  let(:user) { create :admin   }
  render_views
  before(:each) do
    sign_in user
  end

  describe "publication show" do
    it "related person table should not contain birth place column" do
      marc = person.marc
      new_670 = MarcNode.new("person", "670", "", "##")
      ip = marc.get_insert_position("670")
      new_670.add(MarcNode.new("person", "w", "#{resource.id}", nil))
      marc.root.children.insert(ip, new_670)
      person.save
      get :show, params: {id: resource.id}
      page = Capybara::Node::Simple.new(response.body)
      expect(page).not_to have_selector(".col-birth_place")
    end
  end

end
