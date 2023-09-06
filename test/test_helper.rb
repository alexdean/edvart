$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'active_record'
require 'minitest/autorun'
require 'minitest/focus'
require 'pry'
require 'database_cleaner'
# require 'database_cleaner/active_record'

# require 'webmock/minitest'
# WebMock.disable_net_connect!

require_relative '../lib/application_record'
require_relative '../lib/book'
require_relative '../lib/source_url'
require_relative '../lib/local_resource'

DatabaseCleaner.strategy = :transaction

class Minitest::Spec
  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end
end

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'test/books-test.sqlite'
)

ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS source_urls"
ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS local_resources"
ActiveRecord::Base.connection.execute "DROP TABLE IF EXISTS books"

ActiveRecord::Base.connection.execute <<~EOF
  CREATE TABLE "books" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "isbn" text NOT NULL,
    "title" text,
    "author" text,
    "lcc" text,
    "source_url" text,
    "created_at" datetime NOT NULL,
    "updated_at" datetime,
    "local_resource" TEXT
  )
EOF

ActiveRecord::Base.connection.execute <<~EOF
  CREATE TABLE source_urls (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "book_id" INTEGER NOT NULL,
    "url" text NOT NULL,
    "created_at" datetime NOT NULL,
    "updated_at" datetime NOT NULL,
    FOREIGN KEY(book_id) REFERENCES books(id)
  )
EOF

ActiveRecord::Base.connection.execute <<~EOF
  CREATE TABLE local_resources (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT,
    "book_id" INTEGER NOT NULL,
    "path" text NOT NULL,
    "created_at" datetime NOT NULL,
    "updated_at" datetime NOT NULL,
    FOREIGN KEY(book_id) REFERENCES books(id)
  )
EOF
