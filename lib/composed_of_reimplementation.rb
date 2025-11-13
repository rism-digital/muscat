# Hand made simple replacement to composed_of
# As of rails 7, the values are frozen and the "marc"
# variable cannot be modified. https://github.com/rails/rails/pull/46377
#
# The easiest way is to simply expand the composed_of, like this:
#begin
#  def marc
#    @marc ||= MarcSource.new(self.marc_source, self.record_type)
#  end
#
#  def marc=(marc)
#    self.marc_source = marc.to_marc
#    self.record_type = marc.record_type
#    
#    @marc = marc
#  end
# 
# Which does the trick, but since we use it in many models it is a but
# clunky to copy and paste that stuff. Hence an "automated" way to generate
# that code.
# This is NOT a full reimplementation of composed_of, so no converters et al
# The order of the items in the :mapping must also follow the order of the
# constructor of the class, so 
# def initialize(source = nil, rt = 0)
# has to be:
# mapping: [%w(marc_source to_marc), %w(record_type record_type)]
# to follow the argument order
# 
module ComposedOfReimplementation
    extend ActiveSupport::Concern
  
    class_methods do
      def composed_of_reimplementation(attribute_name, class_name:, mapping:)
        define_method(attribute_name) do
          instance_variable_get("@#{attribute_name}") || begin

            # If we have multiple values, we expect an array of arrays
            # [[property1, method1], [property2, method2]]
            if mapping.first.is_a? Array
              mapped_values = mapping.map {|model_attr, class_attr| send(model_attr)}
            else
            # When we only have one value it is just a top-level array;
            # [property1, method1]
              mapped_values = send(mapping.first)
            end
    
            instance_variable_set("@#{attribute_name}", class_name.constantize.new(*mapped_values))
          end
        end
  
        define_method("#{attribute_name}=") do |value|
          if value.is_a?(class_name.constantize)

            if mapping.first.is_a? Array
              mapping.each {|model_attr, class_attr| send("#{model_attr}=", value.send(class_attr))}
            else
              send("#{mapping.first}=", value.send(mapping.second))
            end
            
            instance_variable_set("@#{attribute_name}", value)
          else
            raise ArgumentError, "Expected a #{class_name} object"
          end
        end
      end
    end
  end