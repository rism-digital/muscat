require 'rails_helper'
require "cancan/matchers"

RSpec.describe User do

  describe 'For cataloger abilities for people' do
    let(:cataloger) { FactoryBot.create(:cataloger)  }
    let(:person) { FactoryBot.create(:person)  }
    subject(:ability) { Ability.new(cataloger)  }
    it "should to be able to CR(U) people" do
      expect(ability).to be_able_to(:show, person)
      expect(ability).not_to be_able_to(:update, person)
      expect(ability).to be_able_to(:update, Person.new(:wf_owner => cataloger.id))
      expect(ability).not_to be_able_to(:destroy, person)
      expect(ability).to be_able_to(:create, person)
    end
  end

  describe 'For cataloger abilities for sources' do
    let(:cataloger) { FactoryBot.create(:cataloger)  }
    let(:source) { FactoryBot.create(:manuscript_source)  }
    subject(:ability) { Ability.new(cataloger)  }
    it "should be able to CR(U) sources" do
      expect(ability).to be_able_to(:show, source)
      #TODO test with foreign sources
      #expect(ability).not_to be_able_to(:update, source)
      expect(ability).to be_able_to(:update, Source.new(:wf_owner => cataloger.id))
      expect(ability).not_to be_able_to(:destroy, source)
      expect(ability).to be_able_to(:create, source)
    end
  end

  describe 'For cataloger abilities for works' do
    let(:cataloger) { FactoryBot.create(:cataloger)  }
    let(:work) { FactoryBot.create(:work)  }
    subject(:ability) { Ability.new(cataloger)  }
    it "should be able to CRUD works" do
      expect(ability).not_to be_able_to(:show, work)
      expect(ability).not_to be_able_to(:update, work)
      expect(ability).not_to be_able_to(:destroy, work)
      expect(ability).not_to be_able_to(:create, work)
    end
  end
  
  describe 'Cataloger abilities for editions with own holding' do
    let(:user) { FactoryBot.create(:cataloger) }
    let(:edition) { FactoryBot.create(:edition)  }
    let(:foreign_holding) { FactoryBot.create(:foreign_holding)  }
    let!(:institution) { FactoryBot.create(:institution)  }
    subject(:ability) { Ability.new(user)  }
    it "should not be able to edit edition" do
      edition.holdings.clear
      edition.holdings << foreign_holding
      expect(ability).to be_able_to(:show, edition)
      expect(ability).not_to be_able_to(:edit, edition)
    end
  end
 
  describe 'Cataloger abilities for editions without own holding' do
    let(:user) { FactoryBot.create(:cataloger) }
    let(:edition) { FactoryBot.create(:edition)  }
    let(:foreign_holding) { FactoryBot.create(:foreign_holding)  }
    let!(:institution) { FactoryBot.create(:foreign_institution)  }
    subject(:ability) { Ability.new(user)  }
    it "should not be able to edit edition" do
      edition.holdings.clear
      edition.holdings << foreign_holding
      expect(ability).to be_able_to(:show, edition)
      expect(ability).not_to be_able_to(:edit, edition)
    end
  end
 
end


