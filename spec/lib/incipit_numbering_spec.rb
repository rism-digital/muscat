# frozen_string_literal: true

require 'rspec'
require_relative '../../lib/incipit_numbering'

RSpec.describe IncipitNumbering do
  describe ".invalid_indexes" do
    it "accepts sequential works, movements, and excerpts" do
      tuples = [
        %w[1 1 1],
        %w[1 1 2],
        %w[1 2 1],
        %w[1 2 2],
        %w[2 1 1]
      ]

      expect(described_class.invalid_indexes(tuples)).to be_empty
    end

    it "compares numbers numerically" do
      tuples = [%w[01 01 01], %w[1 1 2], %w[1 2 1]]

      expect(described_class.invalid_indexes(tuples)).to be_empty
    end

    it "requires the first incipit to be 1.1.1" do
      expect(described_class.invalid_indexes([%w[1 1 2]])).to eq([0])
    end

    it "finds a gap between movements" do
      tuples = [%w[1 1 1], %w[1 4 1]]

      expect(described_class.invalid_indexes(tuples)).to eq([1])
    end

    it "requires the excerpt number to restart for a new movement" do
      tuples = (1..8).map { |movement| ["1", movement.to_s, "1"] }
      tuples.concat([%w[1 9 1], %w[1 9 2], %w[1 10 12]])

      expect(described_class.invalid_indexes(tuples)).to eq([10])
    end

    it "finds simultaneous movement and excerpt gaps" do
      tuples = (1..20).map { |movement| ["1", movement.to_s, "1"] }
      tuples.concat([%w[1 21 1], %w[1 21 2], %w[1 23 3]])

      expect(described_class.invalid_indexes(tuples)).to eq([22])
    end

    it "does not treat the excerpt number as a record-wide counter" do
      tuples = [%w[1 1 1], %w[1 2 1], %w[1 2 2], %w[1 2 3], %w[1 2 4], %w[1 3 5]]

      expect(described_class.invalid_indexes(tuples)).to eq([5])
    end

    it "flags non-positive and non-numeric complete numbers" do
      tuples = [%w[0 1 1], %w[one 1 1]]

      expect(described_class.invalid_indexes(tuples)).to eq([0, 1])
    end

    it "leaves incomplete tuples to the completeness validator without cascading" do
      tuples = [["1", nil, "1"], %w[1 2 1]]

      expect(described_class.invalid_indexes(tuples)).to be_empty
    end
  end
end
