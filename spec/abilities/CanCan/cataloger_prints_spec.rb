require 'rails_helper'
require "cancan/matchers"

RSpec.describe User do

  describe 'Cataloger_prints abilities for editions' do
    let(:user) { FactoryBot.create(:cataloger_prints) }
    let(:edition) { FactoryBot.create(:edition)  }
    subject(:ability) { Ability.new(user)  }
    it "should be able to edit edition with own holding" do
      expect(ability).to be_able_to(:show, edition)
      expect(ability).to be_able_to(:edit, edition)
    end
  end
  
  describe 'Cataloger_prints abilities for editions' do
    let(:user) { FactoryBot.create(:cataloger_prints) }
    let(:edition) { FactoryBot.create(:edition)  }
    let!(:foreign_institution) { FactoryBot.create(:foreign_institution)  }
    subject(:ability) { Ability.new(user)  }
    it "should not to be able to edit prints with foreign holdings" do
      edition.holdings.first.institutions.clear
      edition.holdings.first.institutions << foreign_institution
      expect(ability).to be_able_to(:show, edition)
      expect(ability).not_to be_able_to(:edit, edition)
    end
  end

end


