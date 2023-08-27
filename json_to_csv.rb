# read all files in out/json/*
# append any unknowns to call_numbers.csv

require 'pry'
require 'json'
require 'set'
require 'csv'

csv_filename = 'out/call_numbers.csv'

if !File.exist?(csv_filename)
  File.open(csv_filename, 'w') { |fp| fp.write("isbn,title,author,lccn\n") }
end

known_isbns = Set.new
CSV.foreach(csv_filename, headers: true) do |row|
  isbn = row['isbn'].to_s

  if isbn != ''
    known_isbns << isbn
  end
end

csv = CSV.open(csv_filename, "a")

def get_field_values(record, field, subfield=nil)
  subfields = record['fields'].each_with_object([]) do |item, memo|
                if item[field]
                  item[field]['subfields'].each do |sf|
                    if subfield
                      if sf[subfield]
                        memo << sf[subfield]
                      end
                    else
                      memo << sf.values
                    end
                  end
                end
              end
  subfields.join
end

Dir['out/json/*json'].each do |filename|
  record = JSON.parse(File.read(filename))

  author = get_field_values(record, '100')
  title = get_field_values(record, '245', 'a')
  isbn = get_field_values(record, '590', 'a')
  lccn = get_field_values(record, '050')

  if !known_isbns.include?(isbn)
    csv << [isbn, title, author, lccn]
  end
end
