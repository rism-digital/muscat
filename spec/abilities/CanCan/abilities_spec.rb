require 'rails_helper'
require "cancan/matchers"

RSpec.describe User do

  describe 'editor_abilities' do
    let(:editor) { FactoryBot.create(:editor)  }
    let(:person) { FactoryBot.create(:person)  }
    subject(:ability) { Ability.new(editor)  }
    it "editors should not to be able to edit people" do
      expect(ability).not_to be_able_to(:update, person)
      expect(ability).not_to be_able_to(:destroy, person)
      expect(ability).to be_able_to(:create, person)
    end
  end

  describe 'person_editor_abilities' do
    let(:person_editor) { FactoryBot.create(:person_editor)  }
    let(:person) { FactoryBot.create(:person)  }
    subject(:ability) { Ability.new(person_editor)  }
    it "person_editor should be able to edit people" do
      expect(ability).to be_able_to(:update, person)
      expect(ability).to be_able_to(:destroy, person)
      expect(ability).to be_able_to(:create, person)
    end
  end
end

RSpec.describe Role do
  subject(:ability){ Ability.new(user)  }
  let(:user){ FactoryBot.build(:user, roles: [role])  }
  context "when is a editor" do
    let(:role){ FactoryBot.build(:editor_role)  }
    it{ is_expected.to be_able_to(:create, Person.new)  }
    it{ is_expected.to be_able_to(:read, Person.new)  }
    it{ is_expected.not_to be_able_to(:update, Person.new)  }
    it{ is_expected.to be_able_to(:update, Person.new(:wf_owner => user.id))  }
    it{ is_expected.not_to be_able_to(:destroy, Person.new)  }
  end
  
  context "when is a admin" do
    let(:role){ FactoryBot.build(:admin_role)  }
    it{ is_expected.to be_able_to(:create, Person.new)  }
    it{ is_expected.to be_able_to(:read, Person.new)  }
    it{ is_expected.to be_able_to(:update, Person.new)  }
    it{ is_expected.to be_able_to(:destroy, Person.new)  }
  end
end

RSpec.describe Role do
  subject(:ability){ Ability.new(user)  }
  let(:user){ FactoryBot.create(:user, roles: [role, role_people])  }
  context "when is a cataloger with people abilities" do
    let(:role){ FactoryBot.build(:cataloger_role)  }
    let(:role_people){ FactoryBot.build(:person_restricted_role)  }
    it{ is_expected.to be_able_to(:create, Person.new)  }
    it{ is_expected.to be_able_to(:read, Person.new)  }
    it{ is_expected.to be_able_to(:update, Person.new)  }
    it{ is_expected.not_to be_able_to(:destroy, Person.new)  }
  end
end
