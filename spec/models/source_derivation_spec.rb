require "rails_helper"

RSpec.describe Source do
  describe "child derivation" do
    def source_with_marc(record_type, id:, marc_source:)
      described_class.new(
        id: id,
        record_type: MarcSource::RECORD_TYPES.fetch(record_type),
        marc_source: marc_source
      ).tap { |source| source.marc.load_source(false) }
    end

    def child_from_template(record_type)
      default_file = EditorConfiguration.get_source_default_file(record_type)
      template_path = ConfigFilePath.get_marc_editor_profile_path(
        Rails.root.join("config", "marc", RISM::MARC, "source", "#{default_file}.marc").to_s
      )

      source_with_marc(
        record_type,
        id: nil,
        marc_source: File.read(template_path)
      )
    end

    it "maps supported parent types to their child types" do
      expected_types = {
        collection: :source,
        edition: :edition_content,
        theoretica_edition: :theoretica_edition_content,
        libretto_edition: :libretto_edition_content
      }

      expected_types.each do |parent_type, child_type|
        parent = described_class.new(record_type: MarcSource::RECORD_TYPES.fetch(parent_type))
        expect(parent.derived_child_type).to eq(child_type)
        expect(parent).to be_derivable_child
      end
    end

    it "does not derive children from unsupported source types" do
      source = described_class.new(record_type: MarcSource::RECORD_TYPES.fetch(:source))

      expect(source.derived_child_type).to be_nil
      expect(source).not_to be_derivable_child
    end

    it "copies collection fields and generates the parent link" do
      parent = source_with_marc(
        :collection,
        id: 12_345,
        marc_source: <<~MARC
          =001  000012345
          =100  1#$aParent Composer$jAttributed name$dDo not copy
          =650  07$aMasses$0Do not copy
          =650  07$aMotets
          =852  ##$aCH-Bu$cShelf 42$xDo not copy
        MARC
      )
      child = child_from_template(:source)

      child.derive_child_marc_from(parent)

      marc = child.marc.to_marc
      expect(marc).to include("=100  1#$aParent Composer$jAttributed name")
      expect(marc).to include("=650  07$aMasses")
      expect(marc).to include("=650  07$aMotets")
      expect(marc).to include("=852  ##$aCH-Bu$cShelf 42")
      expect(marc).to include("=773  18$w12345")
      expect(marc).not_to include("Do not copy")
      expect(child.marc["100"].size).to eq(1)
      expect(child.marc["650"].size).to eq(2)
      expect(child.marc["852"].size).to eq(1)
    end

    it "does not copy the collection location into an edition child" do
      parent = source_with_marc(
        :edition,
        id: 54_321,
        marc_source: <<~MARC
          =001  000054321
          =100  1#$aParent Composer$jAscertained
          =650  07$aOperas
          =852  ##$aGB-Lbl$cA.1
        MARC
      )
      child = child_from_template(:edition_content)

      child.derive_child_marc_from(parent)

      marc = child.marc.to_marc
      expect(marc).to include("=100  1#$aParent Composer$jAscertained")
      expect(marc).to include("=650  07$aOperas")
      expect(marc).to include("=773  18$w54321")
      expect(marc).not_to include("=852")
    end

    it "rejects an incompatible parent and child combination" do
      parent = source_with_marc(:edition, id: 54_321, marc_source: "=001  000054321\n")
      child = child_from_template(:source)

      expect { child.derive_child_marc_from(parent) }
        .to raise_error(ArgumentError, "Incompatible source types for child derivation")
    end
  end
end
