require 'rails_helper'

RSpec.describe Admin::LiturgicalFeastsController, :type => :controller do 
  render_views
  let!(:feast) { create :liturgical_feast }

  before(:each) do
    @user = FactoryBot.create(:admin)
    sign_in @user
  end

  context "GET index" do
    it do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  context "redirect_to back" do
    it do
      patch :update, params: { :id => feast.id, :liturgical_feast => { :name => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

  context "edit as cataloger" do
    before(:each) do
      sign_out @user
      @user = FactoryBot.create(:cataloger)
      sign_in @user
    end

    it "locks wf_stage to published" do
      get :edit, params: { :id => feast.id }

      expect(response.body).to have_css("input[type='hidden'][name='liturgical_feast[wf_stage]'][value='published']")
    end

    it "forces wf_stage to published on update" do
      patch :update, params: {
        :id => feast.id,
        :liturgical_feast => { :name => feast.name, :wf_stage => "deleted" }
      }

      expect(feast.reload.wf_stage).to eq("published")
    end
  end

end
