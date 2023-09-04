require 'rest-client'
require 'json'
require 'fileutils'
require_relative 'book'

module OpenLibrary
  class Client
    attr_reader :log

    def initialize(logger: nil)
      @log = logger || Logger.new('/dev/null')
    end

    def search(isbn)
      isbn_path = "isbn/#{isbn}.json"
      isbn_data = fetch(isbn_path)

      if isbn_data
        # TEST: no source in db if isbn data not found
        source = source_url(isbn_path)
        local_resource = cache_key(isbn_path)
      end

      lcc = deduplicate_lc_classifications(isbn_data['lc_classifications'])
            .reject { |i| i.to_s == '' }
            .join(' ')

      if !lcc || lcc == ''
        work_data = fetch("#{isbn_data.dig('works', 0, 'key')}.json")
        lcc = work_data.dig('lc_classifications', 0)
      end

      author_data = fetch("#{isbn_data.dig('authors', 0, 'key')}.json")

      Book.new(
        isbn: isbn,
        title: isbn_data['title'],
        author: author_data['name'],
        lcc: lcc,
        source_url: source,
        local_resource: local_resource
      )
    end

    private

    def source_url(path)
      "https://openlibrary.org/#{path}"
    end

    def cache_key(path)
      if path[0] == '/'
        path = path[1..]
      end

      "out/open_library_cache/#{path}"
    end

    def fetch(path)
      key = cache_key(path)

      body = ''
      if File.exist?(key)
        body = File.read(key)
      end

      if !body || body == ''
        url = source_url(path)
        begin
          response = RestClient.get(url)
          body = response.body
          FileUtils.mkdir_p(File.dirname(key))
          File.open(key, 'w') { |fp| fp.write(body) }
        rescue RestClient::NotFound => e
          @log.error "#{path} not found"
          body = '{}'
        end
      end

      begin
        JSON.parse(body)
      rescue JSON::ParserError => e
        {}
      end
    end

    def deduplicate_lc_classifications(values)
      # TEST: de-duplicate entries that only vary by whitespace
      #   "lc_classifications": [
      #     "HT123 .C387 2009",
      #     "",
      #     "HT123.C387 2009"
      #   ],

      # calc hash for each item
      # group values by their hash
      # return a single value from each hash group

      groups = values.group_by { |v| v.to_s.gsub(/ +/, '').downcase }
      groups.map { |key, items| items[0] }
    end
  end
end
