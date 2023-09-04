require_relative '../config/init'

class SourceUrl < ApplicationRecord
  belongs_to :book
end
