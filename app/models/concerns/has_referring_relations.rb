module HasReferringRelations
  extend ActiveSupport::Concern

  class_methods do
    # Defines relation pairs like:
    #   has_many :source_place_relations, class_name: "SourcePlaceRelation"
    #   has_many :referring_sources, through: :source_place_relations, source: :source
    #
    # Example usage:
    #   referring_relations_for :source, :person, :institution
    def referring_relations_for(*models)
      models.each do |model|
        relation_class_name = "#{model.to_s.camelize}#{self.name}Relation"
        relation_name = "#{model}_#{self.name.underscore}_relations"

        has_many relation_name.to_sym, class_name: relation_class_name
        has_many "referring_#{model.to_s.pluralize}".to_sym,
                 through: relation_name.to_sym,
                 source: model
      end
    end
  end
end