module ActiveAdmin
  module Inputs
    module Filters
      class CustomInput < ::Formtastic::Inputs::StringInput
        include Base
        include Base::SearchMethodSelect

        filter :contains, :equals, :starts_with, :ends_with

        def to_html
          input_wrapping do
            label_html << builder.text_field(input_name, input_html_options)
          end
        end

        #def label_text
        #  I18n.t('active_admin.search_field', field: super)
        #end

        def input_html_options
          super.merge(disabled: "disabled")
        end
        
        def input_name
          "#{super}"
        end
      end
    end
  end
end