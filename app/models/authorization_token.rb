class AuthorizationToken < ApplicationRecord
    #def self.ransackable_associations(_) = reflections.keys
    #def self.ransackable_attributes(_) = attribute_names - %w[token]

    def self.ransackable_attributes(auth_object = nil)
        ["name"]
      end

      def self.ransackable_associations(auth_object = nil)
        []
      end
end