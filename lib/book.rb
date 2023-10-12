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

  def lcc_parts
    output = []

    # ascii ranges
    letters = 65..90
    numbers = 48..57

    current_group_type = nil
    current_group = ''
    lcc.to_s.chars.each_with_index do |c|
      if c.bytes.size > 1
        raise "LCC '#{lcc}' contains multibyte character '#{c}'."
      end

      normalized = c.upcase
      type = if letters.include?(normalized.bytes[0])
               :letter
             elsif numbers.include?(normalized.bytes[0])
               :number
             else
               :other
             end

      # init on first iteration only
      if current_group_type.nil?
        current_group_type = type
      end

      # this says "if the current character does not go with the current group"
      if current_group_type != type
        finalize_group(current_group, current_group_type, to: output)

        current_group_type = type
        current_group = ''
      end

      current_group += normalized
    end

    # whatever's left in current_group should be flushed to output.
    finalize_group(current_group, current_group_type, to: output)

    output
  end

  private


  def finalize_group(group, group_type, to:)
    output = to

    if group_type == :number
      output << group.to_i
    elsif group_type == :letter
      output << group
    end
  end
end
