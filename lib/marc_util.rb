require 'nokogiri'
require 'marc'
require 'time'

class MarcUtil
  # convert given marc xml into binary marc & store locally
  #
  # @param [String] marc_xml
  # @param [String] source_url where marc_xml was retrieved from
  # @param [String, Integer] isbn scanned isbn of the work represented by marc_xml
  # @param [String] source Which source organization was the marc retrieved from.
  #    used in generating filename.
  def self.store_local(marc_xml:, source_url:, isbn:, source:)
    if !source.match(/^[a-z]+$/)
      raise ArgumentError, "invalid source #{source}"
    end

    document = Nokogiri::XML(marc_xml)
    document.remove_namespaces!

    # LOC provides this but archive.org does not.
    number_of_records = document.xpath('//numberOfRecords').text
    if number_of_records.present? && number_of_records.to_i == 0
      return nil
    end

    record = document.xpath('//record').first
    reader = MARC::XMLReader.new(StringIO.new(record.to_s))

    marc = reader.map{ |r| r }[0]

    # 59x fields are reserved for local use.
    # we'll use 590 to track how we retrieved this record
    # http://www.loc.gov/marc/bibliographic/bd59x.html
    marc << MARC::DataField.new('590', '0', '0',
      # the UPC/EAN/ISBN that we actually scanned, so it can be used for searches
      ['a', isbn.to_s],
      # and the URL that we retrieved it from
      ['b', source_url],
      ['c', Time.now.utc.iso8601]
    )

    marc_filename = "out/marc/#{isbn.to_s.gsub(':', '-')}-#{source}.marc"
    writer = MARC::Writer.new(marc_filename)
    writer.write(marc)
    writer.close

    [marc, marc_filename]
  end
end
