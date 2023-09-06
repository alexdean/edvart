require 'selenium-webdriver'
require_relative '../book'

module LibraryThing
  class SeleniumClient
    def self.driver
      if !@driver
        options = Selenium::WebDriver::Options.firefox
        @driver = Selenium::WebDriver.for :firefox, options: options
        @driver.manage.timeouts.implicit_wait = 5
      end
      @driver
    end

    def initialize(logger: nil)
      @host = "https://www.librarything.com"
      @log = logger || Logger.new('/dev/null')
    end

    def search(isbn)
      driver = self.class.driver
      driver.get("#{@host}/isbn/#{isbn}")
      details_link = driver.find_element(link_text: "Work details")
      details_link.click

      title = driver.find_element(css: 'div.headsummary h1').text
      author = driver.find_element(css: 'div.headsummary h2').text.gsub(/^by /, '')

      links = driver.find_elements(tag_name: 'a')
      first_lcc_link = links.find { |l| l['href'].to_s.start_with?("https://www.librarything.com/lcc/") }
      lcc = first_lcc_link.text

      # driver.page_source has full HTML

      Book.from_api_data(
        isbn: isbn,
        title: title,
        author: author,
        lcc: lcc,
        source_url: driver.current_url,
        local_resource: nil
      )
    end
  end
end
