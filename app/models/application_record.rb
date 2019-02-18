# Parent Class for the Classes represented in the Database
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
