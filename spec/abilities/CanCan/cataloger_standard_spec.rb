require 'rails_helper'
require "cancan/matchers"

RSpec.describe User do

  context 'with cataloger abilities for people' do
    let(:cataloger) { FactoryBot.create(:cataloger)  }
    let(:person) { FactoryBot.create(:person)  }
    subject(:ability) { Ability.new(cataloger)  }
    it { expect(ability).to be_able_to(:show, person) }
    it { expect(ability).not_to be_able_to(:update, person) }
    it { expect(ability).to be_able_to(:update, Person.new(:wf_owner => cataloger.id)) }
    it { expect(ability).not_to be_able_to(:destroy, person) }
    it { expect(ability).to be_able_to(:create, person) }
  end

  context 'with cataloger abilities for sources' do
    let(:cataloger) { FactoryBot.create(:cataloger)  }
    let(:source) { FactoryBot.create(:manuscript_source)  }
    subject(:ability) { Ability.new(cataloger)  }
    it { expect(ability).to be_able_to(:show, source) }
       #TODO test with foreign sources
       #expect(ability).not_to be_able_to(:update, source)
    it { expect(ability).to be_able_to(:update, Source.new(:wf_owner => cataloger.id)) }
    it { expect(ability).not_to be_able_to(:destroy, source) }
    it { expect(ability).to be_able_to(:create, source) }
  end

  context 'with cataloger abilities for works' do
    let(:cataloger) { FactoryBot.create(:cataloger)  }
    let(:work) { FactoryBot.create(:work)  }
    subject(:ability) { Ability.new(cataloger)  }
    it { expect(ability).not_to be_able_to(:show, work) }
    it { expect(ability).not_to be_able_to(:update, work) }
    it { expect(ability).not_to be_able_to(:destroy, work) }
    it { expect(ability).not_to be_able_to(:create, work) }
  end
  
  context 'with cataloger abilities for editions with own holding' do
    let(:user) { FactoryBot.create(:cataloger) }
    let(:edition) { FactoryBot.create(:edition)  }
    let(:foreign_holding) { FactoryBot.create(:foreign_holding)  }
    let!(:institution) { FactoryBot.create(:institution)  }
    subject(:ability) { Ability.new(user)  }
    it { 
      edition.holdings.clear
      edition.holdings << foreign_holding
      expect(ability).to be_able_to(:show, edition) }
    it { 
      edition.holdings.clear
      edition.holdings << foreign_holding
      expect(ability).not_to be_able_to(:edit, edition) }
  end

  context 'with cataloger abilities for editions without own holding' do
    let(:user) { FactoryBot.create(:cataloger) }
    let(:edition) { FactoryBot.create(:edition)  }
    let(:foreign_holding) { FactoryBot.create(:foreign_holding)  }
    let!(:institution) { FactoryBot.create(:foreign_institution)  }
    subject(:ability) { Ability.new(user)  }
    it { 
      edition.holdings.clear
      edition.holdings << foreign_holding
      expect(ability).to be_able_to(:show, edition) }
    it { 
      edition.holdings.clear
      edition.holdings << foreign_holding
      expect(ability).not_to be_able_to(:edit, edition) }
  end
 
end


