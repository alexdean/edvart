require 'rest-client'
require 'json'
require 'fileutils'
require_relative 'search_result'

module OpenLibrary
  class Client
    def search(isbn)
      isbn_data = fetch("isbn/#{isbn}.json")

      lccn = isbn_data['lc_classifications']&.join(' ')

      if !lccn || lccn == ''
        work_data = fetch("#{isbn_data['works'][0]['key']}.json")
        lccn = work_data.dig('lc_classifications', 0)
      end

      author_data = fetch("#{isbn_data['authors'][0]['key']}.json")

      SearchResult.new(
        isbn: isbn,
        title: isbn_data['title'],
        author: author_data['name'],
        lccn: lccn
      )
    end

    def fetch(path)
      if path[0] == '/'
        path = path[1..]
      end

      cache_key = "out/open_library_cache/#{path}"

      body = ''
      if File.exist?(cache_key)
        body = File.read(cache_key)
      end

      if !body || body == ''
        url = "https://openlibrary.org/#{path}"
        response = RestClient.get(url)
        body = response.body
        FileUtils.mkdir_p(File.dirname(cache_key))
        File.open(cache_key, 'w') { |fp| fp.write(body) }
      end

      JSON.parse(body)
    end
  end
end
