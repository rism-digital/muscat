require 'rails_helper'
model = :work
changeable_ar_attribute = :wf_stage
RSpec.describe Admin::WorksController, type: :controller do
  FactoryBot.create(:person)
  let!(:resource) { create model }
  let(:user) { create :admin   }
  render_views
  before(:each) do
    sign_in user
  end

  describe "INDEX" do
    it "get #{model} index" do
      get :index
      expect(response.status).to eq(200)
    end
  end

  describe "CREATE" do
    it "creating #{model}" do
      #Person.last.destroy
      expect { post :create, :params => FactoryBot.attributes_for(model)   }.to change(model.to_s.capitalize.constantize, :count).by(1)
    end
  end

  describe "SHOW" do
    it "render show template" do
      get :show, params: {id: resource.id}
      expect(response.status).to eq(200)
    end
  end

  describe "UPDATE" do
    it "updating #{model}" do 
      patch :update, params: {:id => resource.id, model => { changeable_ar_attribute => "published"  } }
      resource.reload
      expect(resource[changeable_ar_attribute]).to eq("published")
    end
  end

  describe "DELETE" do
    it "deleting #{model}" do
      delete :destroy, params: {id: resource.id}
      expect(flash[:notice]).to match(/successful/)
    end
  end
end
