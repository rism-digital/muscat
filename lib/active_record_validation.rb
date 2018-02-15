module ActiveRecordValidation

  def checking(level)
    validator = MarcValidator.new(Source.find(self.id), false)
    validator.rules.each do |datafield, rule|
      rule.each do |d,options|
        options.each do |subfield, option|
          if option.is_a?(Hash)
            option.each do |k,v|
              if k == level
                v.each do |method|
                  self.send(method, datafield, subfield)
                end
              end
            end
          end
        end
      end
    end
  end

  def check_mandatory
    checking "mandatory"
  end

  def check_warnings
    checking "warnings"
  end

  def selected_fields(t,s)
    arry = []
    marc.each_by_tag(t) { |tag| tag.each_by_tag(s) {|subfield| arry << subfield if subfield.content } }
    return arry
  end

  def must_have_different_id(t,s)
    selected_fields(t,s).each do |subtag|
      if subtag.content == self.id.to_s
        errors.add(:base, "#{t}$#{s} value '#{subtag.content}' must have different id")
      end
    end
  end

  def should_be_numeric(t, s)
    selected_fields(t,s).each do |subtag|
      unless subtag.content =~ /[0-9]/
        errors.add(:base, "#{t}$#{s} value '#{subtag.content}' is not numeric")
      end
    end
  end

  def should_be_lt_200(t, s)
    selected_fields(t,s).each do |subtag|
      unless subtag.content.to_i < 200
        errors.add(:base, "#{t}$#{s} value '#{subtag.content}' is greater than 200")
      end
    end
  end


end
