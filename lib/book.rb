require_relative '../config/init'

class Book < ApplicationRecord
  has_many :source_urls
  has_many :local_resources

  validates :isbn, presence: true, uniqueness: true
end
