#------------------------------------------------------------------------------
module AwesomePrint
  module MarcNode

    def self.included(base)
      base.send :alias_method, :cast_without_marc_node, :cast
      base.send :alias_method, :cast, :cast_with_marc_node
    end

    # Add marc XML Node and NodeSet names to the dispatcher pipeline.
    #------------------------------------------------------------------------------
    def cast_with_marc_node(object, type)
      cast = cast_without_marc_node(object, type)
      if (defined?(::MarcNode))
        cast = :marc_node
      end
      cast
    end

    #------------------------------------------------------------------------------
    def awesome_marc_node(object)
      if object.is_a? Marc
        out = ""

      object.load_source false
        object.root.children.each do |ch|
           out += awesome_marc_node(ch)
        end
        return out
      end

      out = ""
      object.each do |ch|

        if ch.tag =~ /^[\d]{3,3}$/
          indicator = object.indicator != nil ? object.indicator : "  "
          out += colorize("=#{ch.tag}", :date) + " " + colorize(indicator[0,1], :method) + colorize(indicator[1,1], :method)
        else
          content = ch.content != nil ? ch.content : ""
          out += colorize("$#{ch.tag}", :class) + colorize("#{ch.content}", :variable)
        end
      end
      
      out += "\n"
      out
    end
  end
end

AwesomePrint::Formatter.send(:include, AwesomePrint::MarcNode)