module ThroughAssociations
  extend ActiveSupport::Concern

  class_methods do
    def through_associations
      # Memoize it so it's calculated only once per class
      @through_associations ||= reflect_on_all_associations(:has_many)
        .select { |ref| ref.options[:class_name].present? }
        .map(&:name).select { |n| n.to_s.include?("relations") }
    end

    def through_associations_no_sources
        @through_associations_no_sources ||= reflect_on_all_associations(:has_many)
          .select { |ref| ref.options[:class_name].present? }
          .map(&:name).select { |n| n.to_s.include?("relations") }
          .reject { |n| n.to_s.include?("source") }
          .reject { |n| n.to_s.include?("holding") }
    end

    # "sources" also includes holdings!
    def through_associations_sources
        @through_associations_only_sources ||= reflect_on_all_associations(:has_many)
          .select { |ref| ref.options[:class_name].present? }
          .map(&:name).select { |n| (n.to_s.include?("source") || n.to_s.include?("holding")) && n.to_s.include?("relations") }
    end

    def referring_relations
      StandardTitle.reflect_on_all_associations(:has_many)
      .select { |ref| ref.options[:through].present? }
      .map(&:name).select { |n| n.to_s.include?("referring") }
    end

  end

  def through_associations_total_count
    self.class.through_associations.sum { |assoc| send(assoc).size }
  end

  def through_associations_source_count
    self.class.through_associations_sources.sum { |assoc| send(assoc).size }
  end

  def through_associations_exclude_source_count
    self.class.through_associations_no_sources.sum { |assoc| send(assoc).size }
  end

end
