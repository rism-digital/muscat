require 'rspec'
require 'yaml'
require 'pathname'
require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require_relative '../../lib/settings'
require_relative '../../lib/editor_validation'
require_relative '../../app/models/config_file_path'

RSpec.describe EditorValidation do
  describe '#highlight_class' do
    let(:root) { Pathname.new(File.expand_path('../..', __dir__)) }
    let(:config_dir) { root.join('config/editor_profiles/default/configurations') }
    let(:styles) { YAML.safe_load(File.read(config_dir.join('ValidationStyles.yml'))) }
    let(:rule) { 'required' }
    let(:validation) { described_class.new(validation: 'ExampleValidation') }

    before do
      stub_const('Rails', double(root: root))
      stub_const('RISM', Module.new)
      stub_const('RISM::EDITOR_PROFILE', 'default')
      stub_const('RISM::MARC', 'default')
      allow(IO).to receive(:read).and_call_original
      allow(IO).to receive(:read).with(config_dir.join('ExampleValidation.yml').to_s)
        .and_return({ 'client' => { '999' => { 'tags' => { 'a' => rule } } } }.to_yaml)
      allow(IO).to receive(:read).with(config_dir.join('ValidationStyles.yml').to_s) { styles.to_yaml }
    end

    context 'with a combined rule' do
      let(:rule) { { 'any_of' => ['validate_url', { 'required_if' => { '999' => 'b' } }] } }

      it 'uses mapping order for combined validators, regardless of rule order' do
        styles['validators']['validate_url'] = 'validating-none'

        expect(validation.highlight_class('999', 'a')).to eq('validating-required')
      end

      it 'allows the mapping to give a custom validator priority' do
        styles['validators'] = { 'validate_url' => 'custom-url', 'required_if' => 'validating-required' }

        expect(validation.highlight_class('999', 'a')).to eq('custom-url')
      end
    end

    context 'with a warning-level required rule' do
      let(:rule) { 'required, warning' }

      it 'gives warning styling priority over the required validator' do
        expect(validation.highlight_class('999', 'a')).to eq('validating-warning')
      end

      it 'allows warnings to have no background highlight' do
        styles['warning'] = 'validating-none'

        expect(validation.highlight_class('999', 'a')).to eq('validating-none')
      end
    end

    context 'with an unmapped validator' do
      let(:rule) { { 'must_contain' => 'required' } }

      it 'uses the default without mistaking parameters for validator names' do
        expect(validation.highlight_class('999', 'a')).to eq('validating-other')
      end

      it 'allows the default to suppress background highlights' do
        styles['default'] = 'validating-none'

        expect(validation.highlight_class('999', 'a')).to eq('validating-none')
      end
    end

    context 'with a validator mapped to no color' do
      let(:rule) { 'validate_url' }

      it 'keeps the field subject to validation' do
        styles['validators']['validate_url'] = 'validating-none'

        expect(validation.highlight_class('999', 'a')).to eq('validating-none')
        expect(validation.validate_subtag?('999', 'a')).to be(true)
        expect(validation.get_subtag_rule('999', 'a')).to eq('validate_url')
      end
    end

    context 'with a GND warning' do
      let(:rule) { { 'gnd_warn_default' => 'rda' } }

      it 'uses warning styling' do
        expect(validation.highlight_class('999', 'a')).to eq('validating-warning')
      end
    end

    context 'with a handcrafted warning inside a combined rule' do
      let(:rule) { { 'any_of' => ['validate_calendar', 'handcrafted_warning'] } }

      it 'finds the warning validator in the mapping' do
        expect(validation.highlight_class('999', 'a')).to eq('validating-warning')
      end
    end

    it 'does not highlight a field without a validation rule' do
      expect(validation.highlight_class('999', 'b')).to eq('')
    end
  end
end
