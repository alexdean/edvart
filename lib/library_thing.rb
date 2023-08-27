require 'net/http'
require 'nokogiri'
require 'fileutils'
require_relative 'search_result'

module LibraryThing
  class Client
    def initialize
      @host = "https://www.librarything.com"
    end

    def search(isbn)
      work_path = work_path_for(isbn)
      body = fetch(work_path)
      html = Nokogiri::HTML(body)

      target_href_prefix = '/lcc'
      lccn_path = html.css('a').map { |a| a['href'] }.find { |href| href.to_s.start_with?(target_href_prefix) }
      lccn = lccn_path[(target_href_prefix.size+1)..]

      title = html.css('div.headsummary').css('h1').text
      author = html.css('div.headsummary').css('h2').text.gsub(/^by /, '')

      SearchResult.new(
        isbn: isbn,
        title: title,
        author: author,
        lccn: lccn
      )
    end

    def fetch(path)
      if path[0] == '/'
        path = path[1..]
      end

      cache_key = "out/library_thing_cache/#{path}"

      body = read_cache(cache_key)

      if !body
        uri = URI("#{@host}/#{path}")
        body = Net::HTTP.get(uri)
        write_cache(cache_key, body)
      end

      body
    end

    def work_path_for(isbn)
      cache_key = "out/library_thing_cache/work_path/#{isbn}"

      work_path = read_cache(cache_key)
      return work_path if work_path

      uri = URI("#{@host}/isbn/#{isbn}")
      response = nil
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        request = Net::HTTP::Get.new uri
        response = http.request request
      end
      work_path = response.header['Location']

      write_cache(cache_key, work_path)
      work_path
    end

    def read_cache(cache_key)
      content = nil
      if File.exist?(cache_key)
        content = File.read(cache_key)
      end
      content
    end

    def write_cache(cache_key, content)
      dir = File.dirname(cache_key)
      FileUtils.mkdir_p(dir)
      File.open(cache_key, 'w') { |fp| fp.write(content) }
    end
  end
end
