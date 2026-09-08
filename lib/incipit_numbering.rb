# frozen_string_literal: true

# Validates the hierarchical work, movement, and excerpt numbers in MARC 031.
module IncipitNumbering
  FIRST_NUMBER = [1, 1, 1].freeze

  class << self
    # Return the indexes of complete tuples that do not form a dense,
    # hierarchical sequence. Incomplete tuples are validated elsewhere and do
    # not cause the following tuple to be reported as an additional error.
    def invalid_indexes(tuples)
      parsed = tuples.map { |tuple| parse(tuple) }

      parsed.each_index.select { |index| invalid_at?(tuples, parsed, index) }
    end

    private

    def complete?(tuple)
      tuple&.length == 3 && tuple.all? { |value| !value.to_s.strip.empty? }
    end

    def invalid_at?(tuples, parsed, index)
      return false unless complete?(tuples[index])
      return true unless parsed[index]
      return parsed[index] != FIRST_NUMBER if index.zero?

      previous = parsed[index - 1]
      previous && !valid_transition?(previous, parsed[index])
    end

    def parse(tuple)
      return unless complete?(tuple)

      strings = tuple.map { |value| value.to_s.strip }
      return unless strings.all? { |value| value.match?(/\A\d+\z/) }

      numbers = strings.map(&:to_i)
      numbers if numbers.all?(&:positive?)
    end

    def valid_transition?(previous, current)
      work, movement, excerpt = previous

      [
        [work, movement, excerpt + 1],
        [work, movement + 1, 1],
        [work + 1, 1, 1]
      ].include?(current)
    end
  end
end
