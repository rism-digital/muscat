module ActiveRecordValidation

  def check_mandatory
    validator = MarcValidator.new(Source.find(self.id), false)
    validator.rules.each do |k,v|
      if v["mandatory"]
        v["mandatory"].each do |subfield, methods|
          methods.each do |m|
            self.send(m, k, subfield)
          end
        end
      end
    end
  end

  def check_warnings
    validator = MarcValidator.new(Source.find(self.id), false)
    validator.rules.each do |k,v|
      if v["warnings"]
        v["warnings"].each do |subfield, methods|
          methods.each do |m|
            self.send(m, k, subfield)
          end
        end
      end
    end
  end

  def must_have_different_id(t,s)
    marc.each_by_tag(t) do |tag|
      tag.each_by_tag(s) do |subtag|
        next unless subtag.content
        if subtag.content == self.id.to_s
          errors.add(:base, "#{t}$#{s} must have different id")
        end
      end
    end
  end

  def should_be_numeric(t, s)
    marc.each_by_tag(t) do |tag|
      tag.each_by_tag(s) do |subtag|
        next unless subtag.content
        unless subtag.content =~ /[0-9]/
          errors.add("#{t}$#{s}", "has non-numeric content")
        end
      end
    end
  end

  def should_be_lt_200(t, s)
    marc.each_by_tag(t) do |tag|
      tag.each_by_tag(s) do |subtag|
        next unless subtag.content
        unless subtag.content.to_i < 200
          errors.add("#{t}$#{s}", "is greater than 200")
        end
      end
    end
  end


end
