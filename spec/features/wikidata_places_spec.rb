require 'rails_helper'

RSpec.describe 'Wikidata place import', type: :feature, js: true do
  let(:user) { FactoryBot.create(:editor) }

  before do
    visit user_session_path
    fill_in :user_login, with: user.email
    fill_in :user_password, with: user.password
    click_button('Login')
    visit new_admin_person_path
  end

  it 'requires confirmation for new places while keeping existing places linked' do
    fields = [
      { tag: '551', type: 'datafield', subfields: [
        { code: 'a', content: 'New birthplace' },
        { code: 'i', content: 'go' },
        { code: '0', content: 'IMPORT-NEW' }
      ] },
      { tag: '551', type: 'datafield', subfields: [
        { code: '0', content: 'IMPORT-NEW' },
        { code: 'a', content: 'New death place' },
        { code: 'i', content: 'so' }
      ] },
      { tag: '551', type: 'datafield', subfields: [
        { code: 'a', content: 'Existing place' },
        { code: 'i', content: 'go' },
        { code: '0', content: '123' }
      ] }
    ]

    page.execute_script('_marc_editor_update_from_json(arguments[0], [], true)', { fields: fields })

    places = all(".tag_toplevel_container[data-tag='551']", count: 3)
    places.first(2).each do |place|
      expect(place).to have_css('.checkbox_confirmation', text: 'Confirm the insertion of a new value')
      expect(place).to have_css('.autocomplete_new_window.serialize_marc.new_autocomplete')
      expect(place).to have_css('.autocomplete_target:not(.serialize_marc):not(.validate_551_0)', visible: :all)
      checkbox = place.find('.creation_checkbox')
      expect(checkbox).not_to be_checked
      expect(page.evaluate_script('marc_validate_new_creation("", arguments[0])', checkbox)).to be(false)
      checkbox.check
      expect(page.evaluate_script('marc_validate_new_creation("", arguments[0])', checkbox)).to be(true)
    end

    expect(places.last).not_to have_css('.checkbox_confirmation')
    expect(places.last).to have_css('.autocomplete_target.serialize_marc[value="123"]', visible: :all)
    expect(places.last).not_to have_css('.autocomplete_new_window.serialize_marc')
  end
end
