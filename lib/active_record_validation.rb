module ActiveRecordValidation

  def checking(level)
    validator = MarcValidator.new(Source.new, false)
    validator.rules.each do |datafield, rule|
      rule.each do |d,options|
        options.each do |subfield, option|
          if option.is_a?(Hash)
            option.each do |k,v|
              if k == level
                v.each do |method|
                  self.send(method, {datafield: datafield, subfield: subfield})
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

  def must_have_different_id(hash={})
    t,s = hash[:datafield], hash[:subfield]
    marc.all_values_for_tags_with_subtag(t,s).each do |subtag|
      if subtag == self.id.to_s
        errors.add(:base, "#{t}$#{s} value '#{subtag}' must have different id")
      end
    end
  end

  def should_be_numeric(hash={})
    t,s = hash[:datafield], hash[:subfield]
    marc.all_values_for_tags_with_subtag(t,s).each do |subtag|
      unless subtag =~ /[0-9]/
        errors.add(:base, "#{t}$#{s} value '#{subtag}' is not numeric")
      end
    end
  end

  def should_be_lt_200(hash={})
    t,s = hash[:datafield], hash[:subfield]
    marc.all_values_for_tags_with_subtag(t,s).each do |subtag|
      unless subtag.to_i < 200
        errors.add(:base, "#{t}$#{s} value '#{subtag}' is greater than 200")
      end
    end
  end

  def must_have_ability_to_create(hash={})   
    if versions.empty?
      return unless user
      return if user.has_role?("admin") || user.has_role?("editor")
      sigla = []
      workgroup_sigla = []
      user.workgroups.each do |w|
        w.institutions.map {|i| workgroup_sigla << i.id}
      end
      return if workgroup_sigla.empty?
      marc.each_by_tag("852") do |e|
        e.each_by_tag("x") do |i|
          sigla << i.content.to_i rescue next
        end
      end
      sigla.each do |siglum|
        unless workgroup_sigla.include?(siglum)
          library = Institution.where(id: siglum).take
          errors.add(:base, "Your are not allowed to create sources with siglum '#{library.siglum}'.")
          return
        end
      end
    end
  end

end
