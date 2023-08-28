# iterate through out/marc/*
# insert records into sqlite
require 'pry'
require 'marc'
require_relative 'lib/book'

Book.db = 'out/books.sqlite'

Dir['out/marc/*.marc'].each do |filename|
  # puts filename
  no_isbn = ['out/marc/9780385416276.marc', 'out/marc/8070280298.marc']
  if no_isbn.include?(filename)
    next
  end

  base = File.basename(filename, '.marc')
  json_filename = "out/json/#{base}.json"

  reader = MARC::Reader.new(File.open(filename))
  marc = nil
  reader.each { |r| marc = r}

  if !marc || !marc['590']
    binding.pry
  end

  b = Book.new(
    isbn: marc['590']['a']
  )

  lcc_field = marc['050']
  if lcc_field
    b.lcc = lcc_field.subfields.map(&:value).join
  else
    if marc['099']
      b.lcc = marc['099']['a']
    end
  end

  title_field = marc['245']
  if title_field
    b.title = title_field['a']
  else
    binding.pry
  end

  author_field = marc['100'] || marc['700']
  if author_field
    b.author = author_field.subfields.map(&:value).join
  end

  b.local_resource = filename


  b.persist
end
