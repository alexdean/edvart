require 'net/http'
require 'nokogiri'
require 'fileutils'
require_relative 'book'

module LibraryThing
  class Client
    attr_reader :log

    def initialize(logger: nil)
      @host = "https://www.librarything.com"
      @log = logger || Logger.new('/dev/null')
    end

    def search(isbn)
      work_path = work_path_for(isbn)
      body = fetch(work_path)
      html = Nokogiri::HTML(body)

      target_href_prefix = '/lcc'
      lcc_path = html.css('a').map { |a| a['href'] }.find { |href| href.to_s.start_with?(target_href_prefix) }
      lcc = nil
      if lcc_path
        lcc = lcc_path[(target_href_prefix.size+1)..]
      end

      title = html.css('div.headsummary').css('h1').text
      author = html.css('div.headsummary').css('h2').text.gsub(/^by /, '')

      Book.new(
        isbn: isbn,
        title: title,
        author: author,
        lcc: lcc,
        source_url: source_url(work_path),
        local_resource: cache_key(work_path)
      )
    end

    private

    def source_url(path)
      if path[0] == '/'
        path = path[1..]
      end

      "#{@host}/#{path}"
    end

    def cache_key(path)
      if path[0] == '/'
        path = path[1..]
      end

      "out/library_thing_cache/#{path}"
    end

    def fetch(path)
      key = cache_key(path)

      body = read_cache(key)

      if !body
        uri = URI(source_url(path))
        body = Net::HTTP.get(uri)
        write_cache(key, body)
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

      if work_path.start_with?('/verify.php')
        raise "redirected to /verify.php"
      else
        write_cache(cache_key, work_path)
      end

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
