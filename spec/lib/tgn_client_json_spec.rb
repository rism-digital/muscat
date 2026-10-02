require 'rspec'
require_relative '../../lib/tgn_client_json'

RSpec.describe TgnClientJson do
  describe '.normalize_place_id' do
    it 'accepts a numeric TGN ID' do
      expect(described_class.normalize_place_id('7102707')).to eq('7102707')
    end

    it 'accepts the tgn: prefix' do
      expect(described_class.normalize_place_id('tgn:7102707')).to eq('7102707')
    end

    it 'accepts the TGN mirror URL' do
      expect(described_class.normalize_place_id('https://tgn-mirror.rism.online/places/7102707')).to eq('7102707')
    end

    it 'accepts Getty vocabulary URLs' do
      expect(described_class.normalize_place_id('https://vocab.getty.edu/tgn/7102707/')).to eq('7102707')
    end

    it 'unwraps a Markdown link and trims non-breaking whitespace' do
      pasted_link = "[https://tgn-mirror.rism.online/places/7102707](https://tgn-mirror.rism.online/places/7102707)\u00a0 "

      expect(described_class.normalize_place_id(pasted_link)).to eq('7102707')
    end

    it 'rejects URLs from unsupported hosts' do
      expect { described_class.normalize_place_id('https://example.com/places/7102707') }
        .to raise_error(TgnClientJson::InvalidPlaceIdError)
    end

    it 'rejects non-numeric place IDs' do
      expect { described_class.normalize_place_id('https://tgn-mirror.rism.online/places/abc') }
        .to raise_error(TgnClientJson::InvalidPlaceIdError)
    end
  end
end
