require_relative '../config/init'

class LocalResource < ApplicationRecord
  belongs_to :book
end
