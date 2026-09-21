# This renderer test runs without the application, database or Solr.
require 'rspec/mocks'
require 'rspec/mocks/matchers/receive'
require 'rails/all'
require 'active_admin'
require 'nokogiri'
require_relative '../../lib/source_index'
require_relative '../../lib/active_admin/views/index_as_source_table'

RSpec.describe ActiveAdmin::Views::IndexAsSourceTable::SourceTableFor do
  around do |example|
    I18n.backend.load_translations(File.expand_path('../../config/locales/en.yml', __dir__))
    I18n.with_locale(:en) { example.run }
  end

  it 'renders tombstones across all columns without evaluating actions or selection blocks' do
    view_helpers = ActionView::Base.empty
    context = Arbre::Context.new({}, view_helpers)
    allow(view_helpers).to receive(:request).and_return(double(query_parameters: {}))
    stub_const('IndexSource', Struct.new(:id))
    source = IndexSource.new(2)
    allow(view_helpers).to receive(:format_attribute) { |record, data| data.call(record) }

    table = context.insert_tag described_class, [SourceIndex::Tombstone.new('1'), source], sortable: false do |renderer|
      %w[Select ID Title Actions].each do |title|
        renderer.column(title) do |record|
          raise 'Tombstone reached a normal column' if record.is_a?(SourceIndex::Tombstone)
          "#{title} #{record.id}"
        end
      end
    end

    html = Nokogiri::HTML.fragment(table.to_s)
    rows = html.css('tbody tr')
    expect(rows.size).to eq(2)
    expect(rows.first.css('td').size).to eq(1)
    expect(rows.first.at_css('td')['colspan']).to eq('4')
    expect(rows.first.text).to include('Source 1: this record exists in SOLR but not in the database.')
    expect(rows.first.text).to include('This is annoying but innocuous, please contact the administrator if you see this message.')
    expect(rows.first.css('a, input')).to be_empty
    expect(rows.last.css('td').size).to eq(4)
    expect(rows.last.text).to include('Title 2', 'Actions 2')
  end
end
