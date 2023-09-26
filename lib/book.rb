class Book < ApplicationRecord
  has_many :source_urls
  has_many :local_resources

  validates :isbn, presence: true, uniqueness: true

  before_validation do
    self.barcode ||= self.isbn
  end

  # initialize a Book and add data to it.
  # designed to only add data, so a `nil` value will not replace a non-nil value.
  #
  # @return [Book]
  def self.from_api_data(isbn:, title: nil, author: nil, lcc: nil, source_url: nil, local_resource: nil)
    book = Book.find_or_initialize_by(isbn: isbn)
    book.add_data!(title: title, author: author, lcc: lcc, source_url: source_url, local_resource: local_resource)
    book
  end

  def add_data!(title: nil, author: nil, lcc: nil, source_url: nil, local_resource: nil)
    if title
      self.title = title
    end
    if author
      self.author = author
    end
    if lcc
      self.lcc = lcc
    end

    if source_url && !self.source_urls.where(url: source_url).exists?
      self.source_urls.build(url: source_url)
    end

    if local_resource && !self.local_resources.where(path: local_resource).exists?
      self.local_resources.build(path: local_resource)
    end
  end
end
