# iterate through out/marc/*
# create an out/json equivalent for each MARC file

require 'marc'
require 'logger'

log = Logger.new($stdout)

Dir['out/marc/*.marc'].each do |filename|
  # puts filename
  base = File.basename(filename, '.marc')
  json_filename = "out/json/#{base}.json"

  log.info "#{filename} -> #{json_filename}"

  reader = MARC::Reader.new(File.open(filename))
  writer = MARC::JSONLWriter.new(json_filename)
  reader.each { |record| writer.write(record) }
  writer.close
end
