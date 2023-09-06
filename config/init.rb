# include this in scripts or from console sessions

this_dir = File.expand_path('../', __FILE__)
load "#{this_dir}/zeitwerk.rb"

require 'active_record'
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'out/books.sqlite'
)
