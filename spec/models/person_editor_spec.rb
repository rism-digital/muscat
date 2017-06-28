require 'rails_helper'
require "cancan/matchers"

RSpec.describe User do

  describe 'editor_abilities' do
    let(:editor) { FactoryGirl.create(:editor)  }
    let(:person) { FactoryGirl.create(:person)  }
    subject(:ability) { Ability.new(editor)  }
    it "editors should not to be able to edit people" do
      expect(ability).not_to be_able_to(:update, person)
    end
  end

  describe 'person_editor_abilities' do
    let(:person_editor) { FactoryGirl.create(:person_editor)  }
    let(:person) { FactoryGirl.create(:person)  }
    subject(:ability) { Ability.new(person_editor)  }
    it "person_editor should be able to edit people" do
      expect(ability).to be_able_to(:update, person)
    end
  end



end
