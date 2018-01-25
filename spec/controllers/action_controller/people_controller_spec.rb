require 'rails_helper'
model = :person
changeable_ar_attribute = :wf_stage
RSpec.describe Admin::PeopleController, type: :controller do
  let!(:resource) { create model  }
  let(:user) { create :admin   }
  render_views
  before(:each) do
    sign_in user
  end

  describe "INDEX" do
    it "get persons index" do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe "CREATE" do
    it "creating person" do
      expect { post :create, :params => {model => FactoryBot.attributes_for(model)}   }.to change(model.to_s.capitalize.constantize, :count).by(1)
    end
  end

  describe "SHOW" do
    it "render show template" do
      get :show, id: resource.id
      expect(response.status).to eq(200)
    end
  end

  describe "UPDATE" do
    it "updating person" do 
      patch :update, :id => resource.id, model => { changeable_ar_attribute => 1  } 
      resource.reload
      expect(resource[changeable_ar_attribute]).to eq(1)
    end
  end

  describe "DELETE" do
    it "deleting resource" do
      delete :destroy, id: resource.id
      expect(flash[:notice]).to match(/successful/)
    end
  end
end
