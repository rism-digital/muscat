# see https://gist.github.com/rdj/1057991

module ActiveAdmin
  module Inputs
    module Filters
      class RecordTypeInput < ::Formtastic::Inputs::HiddenInput
        include Base
        include Base::SearchMethodSelect

        filter :contains, :equals, :starts_with, :ends_with

        def to_html
          input_wrapping do
            label_html << builder.hidden_field(input_name, input_html_options)
          end
        end

        def label_text
          value = @object.send("record_type_with_integer")
          # "record_type:1"
          toks = value.split(":")
          if toks.count > 1
            record_type = MarcSource::RECORD_TYPES.key(toks[1].to_i)
            "#{I18n.t(:filter_record_type)}: #{I18n.t("record_types." + record_type.to_s)}"
          else
            "Unknown param: #{value}"
          end
        end

        def input_name
          "#{super}"
        end
      end
    end
  end
end
