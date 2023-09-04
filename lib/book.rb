require 'sqlite3'

class Book
  attr_accessor :isbn, :title, :author, :lcc, :source_url, :local_resource

  def self.db=(path)
    @db = SQLite3::Database.new path
    @db.execute <<-EOF
      CREATE TABLE IF NOT EXISTS "books" (
        "isbn" text NOT NULL,
        "title" text,
        "author" text,
        "lcc" text,
        "source_url" text,
        "created_at" datetime NOT NULL,
        "local_resource" TEXT,
        PRIMARY KEY (isbn)
      )
    EOF
  end

  def self.query(...)
    @db.query(...)
  end

  def self.exist?(isbn)
    result = @db.execute("select isbn from books where isbn = '#{isbn}'")
    result.size > 0
  end

  def self.all
    out = []
    sql = <<~EOF
      SELECT
        isbn,
        title,
        author,
        lcc,
        source_url,
        local_resource
      FROM books
      ORDER BY lcc
    EOF

    query(sql).map do |row|
      field_names = row.fields.map(&:to_sym)
      h = field_names.zip(row).to_h
      Book.new(**h)
    end
  end

  def initialize(isbn: nil, title: nil, author: nil, lcc: nil, source_url: nil, local_resource: nil)
    @isbn = isbn
    @title = title
    @author = author
    @lcc = lcc
    @source_url = source_url
    @local_resource = local_resource
  end

  def valid?
    !isbn.nil? && (!lcc.nil? && lcc != '')
  end

  def persist
    if !isbn
      raise "cannot save book w/o isbn"
    end

    self.class.query(
      "REPLACE INTO books (isbn, title, author, lcc, source_url, local_resource, created_at)
       VALUES            (   ?,     ?,      ?,   ?,          ?,              ?,          ?)",
        isbn,
        title,
        author,
        lcc,
        source_url,
        local_resource,
        Time.now.utc.iso8601
      )
  end
end
