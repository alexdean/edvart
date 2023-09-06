class Book < ApplicationRecord
  has_many :source_urls
  has_many :local_resources

  validates :isbn, presence: true, uniqueness: true

  # initialize a Book and add data to it.
  # designed to only add data, so a `nil` value will not replace a non-nil value.
  #
  # @return [Book]
  def self.from_api_data(isbn:, title: nil, author: nil, lcc: nil, source_url: nil, local_resource: nil)
    book = Book.find_or_initialize_by(isbn: isbn)

    if title
      book.title = title
    end
    if author
      book.author = author
    end
    if lcc
      book.lcc = lcc
    end

    if source_url && !book.source_urls.where(url: source_url).exists?
      book.source_urls.build(url: source_url)
    end

    if local_resource && !book.local_resources.where(path: local_resource).exists?
      book.local_resources.build(path: local_resource)
    end

    book
  end
end
