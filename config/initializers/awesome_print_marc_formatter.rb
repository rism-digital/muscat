# Syntax highlighting for Muscat MARC records in Awesome Print.
module AwesomePrint
  module MarcFormatter
    def cast(object, type)
      return :muscat_marc if defined?(::Marc) && object.is_a?(::Marc)

      super
    end

    def awesome_muscat_marc(object)
      copy = object.deep_copy
      copy.load_source(false) unless copy.loaded
      colorize_marc(copy.to_marc)
    end

    private

    def colorize_marc(marc)
      marc.each_line.map { |line| colorize_marc_line(line) }.join
    end

    def colorize_marc_line(line)
      match = line.match(/\A=(\w{3})  (.*?)(\r?\n)?\z/)
      return line unless match

      tag = match[1]
      body = match[2]
      newline = match[3].to_s
      output = colorize("=#{tag}", :date) + "  "

      if tag.to_i < 10
        output + colorize(body, :variable) + newline
      else
        indicators = body.slice!(0, 2).to_s.ljust(2)
        output + colorize(indicators[0], :method) +
          colorize(indicators[1], :method) +
          colorize_marc_subfields(body) + newline
      end
    end

    def colorize_marc_subfields(body)
      body.gsub(/(\$[\dA-Za-z_])([^$]*)/) do
        colorize(Regexp.last_match(1), :class) +
          colorize(Regexp.last_match(2), :variable)
      end
    end
  end
end

AwesomePrint::Formatter.prepend(AwesomePrint::MarcFormatter)
