require 'logger'
require 'nokogiri'
require 'rest-client'
require 'marc'
require 'time'

module LocSru
  # search client for Library of Congress catalogue using SRU protocol
  class Client
    # discovery at http://lx2.loc.gov:210/LCDB
    # example query:
    #   http://lx2.loc.gov:210/lcdb?version=1.1&operation=searchRetrieve&query=bath.isbn=9780306824777&recordSchema=marcxml&maximumRecords=1
    #   can also search by bath.lccn=
    #   http://lx2.loc.gov:210/lcdb?version=1.1&operation=searchRetrieve&recordSchema=marcxml&maximumRecords=1&query=bath.lccn=68008971

    attr_reader :log

    def initialize(logger: nil)
      @log = logger || Logger.new('/dev/null')
    end

    def search(isbn)
      isbn = isbn.to_s

      base_query = {
        version: '1.1',
        operation: 'searchRetrieve',
        recordSchema: 'marcxml',
        maximumRecords: 1
      }

      response = RestClient.get('http://lx2.loc.gov:210/lcdb',
        params: base_query.merge(query: build_sru_query(isbn))
      )
      document = Nokogiri::XML(response.body)
      document.remove_namespaces!

      if document.xpath('//numberOfRecords').text.to_i == 0
        return Book.new(isbn: isbn)
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

      marc_filename = "out/marc/#{isbn.to_s.gsub(':', '-')}.marc"
      writer = MARC::Writer.new(marc_filename)
      writer.write(marc)
      writer.close

      author = nil
      author_field = marc['100'] || marc['700']
      if author_field
        author = author_field.subfields.map(&:value).join
      end

      lcc = nil
      lcc_field = marc['050']
      if lcc_field
        lcc = lcc_field.subfields.map(&:value).join
      else
        if marc['099']
          lcc = marc['099']['a']
        end
      end

      Book.from_api_data(
        isbn: isbn,
        title: "#{marc['245']['a']}#{marc['245']['p']}",
        author: author,
        lcc: lcc,
        source_url: response.request.url,
        local_resource: marc_filename
      )
    end

    private

    # build an SRU query from the isbn
    #
    # inputs are assumed to be isbn-ish (maybe EAN, etc) number
    # unless they begin with 'lccn:', in which case they are considered to be
    # Library of Congress control numbers.
    #
    # @return [String] a query fragment usable on an SRU server like lx2.loc.gov
    def build_sru_query(input)
      if input[0..4] == 'lccn:'
        "bath.lccn=#{input[5..-1]}"
      else
        "bath.isbn=#{input}"
      end
    end
  end
end
