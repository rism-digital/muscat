require 'rails_helper'
require "cancan/matchers"

RSpec.describe User do

  describe 'For editor abilities for people' do
    let(:editor) { FactoryBot.create(:editor)  }
    let(:person) { FactoryBot.create(:person)  }
    subject(:ability) { Ability.new(editor)  }
    it "should not to be able to edit people" do
      expect(ability).not_to be_able_to(:update, person)
      expect(ability).not_to be_able_to(:destroy, person)
      expect(ability).to be_able_to(:create, person)
    end
  end

  describe 'For editor abilities for sources' do
    let(:editor) { FactoryBot.create(:editor)  }
    let(:source) { FactoryBot.create(:manuscript_source)  }
    subject(:ability) { Ability.new(editor)  }
    it "should be able to CRUD sources" do
      expect(ability).to be_able_to(:show, source)
      expect(ability).to be_able_to(:update, source)
      expect(ability).to be_able_to(:destroy, source)
      expect(ability).to be_able_to(:create, source)
    end
  end

  describe 'For editor abilities for works' do
    let(:editor) { FactoryBot.create(:editor)  }
    let(:work) { FactoryBot.create(:work)  }
    subject(:ability) { Ability.new(editor)  }
    it "should be able to CRUD works" do
      expect(ability).to be_able_to(:show, work)
      expect(ability).to be_able_to(:update, work)
      expect(ability).to be_able_to(:destroy, work)
      expect(ability).to be_able_to(:create, work)
    end
  end
end


