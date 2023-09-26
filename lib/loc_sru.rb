require 'logger'
require 'rest-client'

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

      marc, marc_filename = MarcUtil.store_local(
                              marc_xml: response.body,
                              source_url: response.request.url,
                              isbn: isbn,
                              source: 'loc'
                            )
      if !marc
        # TODO: test. if marc not found, but isbn already in db, we return existing record.
        return Book.from_api_data(isbn: isbn)
      end

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
