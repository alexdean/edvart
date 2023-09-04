require 'active_record'

require_relative '../lib/application_record'
require_relative '../lib/source_url'
require_relative '../lib/local_resource'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'out/books.sqlite'
)
