# script receives UPC/EAN/ISBN numbers on stdin
# and tries to fetch a MARC record for each.
#
# script runs until interrupted.
# primary intent is to receive input from a barcode scanner.

require 'io/console'
require 'thread'
require 'logger'
require 'nokogiri'
require 'rest-client'
require 'marc'
require 'time'
require 'colorize'
require 'sqlite3'

# discovery at http://lx2.loc.gov:210/LCDB
# example query:
#   http://lx2.loc.gov:210/lcdb?version=1.1&operation=searchRetrieve&query=bath.isbn=9780306824777&recordSchema=marcxml&maximumRecords=1

trap('SIGINT') do
  puts 'exiting.'
  exit
end

log = Logger.new($stdout).tap { |l| l.level = Logger::INFO }
db = SQLite3::Database.new 'out/unknowns.sqlite'

db.execute <<-EOF
  CREATE TABLE IF NOT EXISTS unknowns (
    id TEXT NOT NULL PRIMARY KEY,
    last_scanned_at TEXT NOT NULL
  )
EOF

def find_and_write_marc(isbn, log, db)
  begin
    base_query = {
      version: '1.1',
      operation: 'searchRetrieve',
      recordSchema: 'marcxml',
      maximumRecords: 1
    }

    log.info "#{isbn} : start."

    response = RestClient.get('http://lx2.loc.gov:210/lcdb',
      params: base_query.merge(query: "bath.isbn=#{isbn}")
    )
    document = Nokogiri::XML(response.body)
    document.remove_namespaces!

    if document.xpath('//numberOfRecords').text.to_i == 0
      log.warn "\a#{isbn} : not found.".colorize(:light_red)
      db.query("REPLACE INTO unknowns (id, last_scanned_at) VALUES (?, ?)", isbn, Time.now.utc.iso8601)
      return
    end

    record = document.xpath('//record').first
    reader = MARC::XMLReader.new(StringIO.new(record.to_s))

    marc = reader.map{ |r| r }[0]

    # 59x fields are reserved for local use.
    # we'll use 590 to track how we retrieved this record
    # http://www.loc.gov/marc/bibliographic/bd59x.html
    marc << MARC::DataField.new('590', '0', '0',
      # the UPC/EAN/ISBN that we actually scanned, so it can be used for searches
      ['a', isbn],
      # and the URL that we retrieved it from
      ['b', response.request.url],
      ['c', Time.now.utc.iso8601]
    )

    writer = MARC::Writer.new("out/#{isbn}.marc")
    writer.write(marc)
    writer.close

    # print the title. http://www.loc.gov/marc/bibliographic/bd20x24x.html
    log.info "\a#{isbn} : finished. '#{marc['245']['a']}'".colorize(:light_green)
  rescue => e
    log.error "\a#{isbn} : #{e.class} #{e.message} ".colorize(:light_red)
  end
end

log.info "Started. Enter ISBN numbers now."

loop do
  isbn = STDIN.noecho{ gets }.strip
  Thread.new { find_and_write_marc(isbn, log, db) }
end
