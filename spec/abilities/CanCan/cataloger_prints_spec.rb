require 'rails_helper'
require "cancan/matchers"

RSpec.describe User do

  describe 'DEPRECATED:Cataloger_prints abilities for editions' do
    let(:user) { FactoryBot.create(:cataloger) }
    let(:edition) { FactoryBot.create(:edition)  }
    subject(:ability) { Ability.new(user)  }
    it "should be able to edit edition with own holding" do
      expect(ability).to be_able_to(:show, edition)
      expect(ability).to be_able_to(:edit, edition)
    end
  end
  
  describe 'DEPRECATED: Cataloger_prints abilities for editions' do
    let(:user) { FactoryBot.create(:cataloger) }
    let(:workgroup) { FactoryBot.create(:workgroup) }
    let(:edition) { FactoryBot.create(:edition)  }
    let!(:foreign_holding) { FactoryBot.create(:foreign_holding)  }
    subject(:ability) { Ability.new(user)  }
    it "should not to be able to edit prints with foreign holdings" do
      user.workgroups << workgroup
      edition.holdings.clear
      edition.holdings << foreign_holding
      expect(ability).to be_able_to(:show, edition)
      expect(ability).not_to be_able_to(:edit, edition)
    end
  end

end


