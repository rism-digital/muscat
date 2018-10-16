# see https://gist.github.com/rdj/1057991

module ActiveAdmin
  module Inputs
    module Filters
      class LibSiglumInput < ::Formtastic::Inputs::HiddenInput
        include Base
        include Base::SearchMethodSelect

        filter :contains, :equals, :starts_with, :ends_with

        def to_html
          input_wrapping do
            label_html << builder.hidden_field(input_name, input_html_options)
          end
        end

        def label_text
          value = @object.send("lib_siglum_with_integer")
          # "lib_siglum:ch-lib"
          toks = value.split(":")
          if toks.count > 1
            lib_siglum = toks[1]
            "#{I18n.t(:filter_lib_siglum)}: #{lib_siglum}" 
          else
            "Unknown siglum: #{value}"
          end
        end

        def input_name
          "#{super}"
        end
      end
    end
  end
end
