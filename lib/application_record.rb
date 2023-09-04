require_relative '../config/init'

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
