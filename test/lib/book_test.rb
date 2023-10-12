require 'test_helper'

describe Book do
  describe '.from_api_data' do
    describe 'when isbn is not already in db' do
      it 'initializes a new instance' do
        subject = Book.from_api_data(
                    isbn: 'isbn',
                    title: 'title',
                    author: 'author',
                    lcc: 'lcc',
                    source_url: 'source_url',
                    local_resource: 'local_resource'
                  )
        assert subject.new_record?
        assert_equal 'isbn', subject.isbn
        assert_equal 'title', subject.title
        assert_equal 'author', subject.author
        assert_equal 'lcc', subject.lcc
        assert_equal 1, subject.source_urls.size
        assert_equal 'source_url', subject.source_urls[0].url
        assert_equal 1, subject.local_resources.size
        assert_equal 'local_resource', subject.local_resources[0].path
      end
    end

    describe 'when isbn is already in the db' do
      before do
        book = Book.from_api_data(
                 isbn: 'isbn',
                 title: 'title',
                 author: 'author',
                 lcc: 'lcc',
                 source_url: 'source_url',
                 local_resource: 'local_resource'
               )
        book.save!
      end

      it 'updates existing values' do
        subject = Book.from_api_data(
                    isbn: 'isbn',
                    title: 'title2',
                    author: 'author2',
                    lcc: 'lcc2'
                  )
        assert !subject.new_record?
        assert_equal 'isbn', subject.isbn
        assert_equal 'title2', subject.title
        assert_equal 'author2', subject.author
        assert_equal 'lcc2', subject.lcc
        assert_equal 1, subject.source_urls.size
        assert_equal 1, subject.local_resources.size
        assert_equal ['title', 'author', 'lcc'], subject.changes.keys
      end

      it 'does not nullify existing values' do
        subject = Book.from_api_data(
                    isbn: 'isbn',
                    title: nil,
                    author: nil,
                    lcc: nil
                  )

        assert !subject.new_record?
        assert_equal 'isbn', subject.isbn
        assert_equal 'title', subject.title
        assert_equal 'author', subject.author
        assert_equal 'lcc', subject.lcc
      end

      it 'adds a new source url' do
        subject = Book.from_api_data(isbn: 'isbn', source_url: 'url2')
        assert_equal ['source_url', 'url2'], subject.source_urls.map(&:url)
      end

      it 'adds a new local resource' do
        subject = Book.from_api_data(isbn: 'isbn', local_resource: 'path2')
        assert_equal ['local_resource', 'path2'], subject.local_resources.map(&:path)
      end
    end
  end

  describe '#lcc_parts' do
    it 'splits lcc into alphabetical and numeric groups' do
      outputs = []
      subject = Book.new

      subject.lcc = "BH301.M54M44 1987"
      outputs << subject.lcc_parts

      subject.lcc = "GV1469.D84 G938"
      outputs << subject.lcc_parts

      # sequential 'other' characters
      subject.lcc = "GV1469.D84  G938"
      outputs << subject.lcc_parts

      # starts with non-alphanum
      subject.lcc = " GV1469.D84 G938"
      outputs << subject.lcc_parts

      # new group on last character
      subject.lcc = "GV1469.D84 G938P"
      outputs << subject.lcc_parts

      # ends with non-alphanum
      subject.lcc = "GV1469.D84 G938."
      outputs << subject.lcc_parts

      # puts outputs.inspect

      assert_equal(["BH", 301, "M", 54, "M", 44, 1987], outputs[0])
      assert_equal(["GV", 1469, "D", 84, "G", 938], outputs[1])
      assert_equal(["GV", 1469, "D", 84, "G", 938], outputs[2])
      assert_equal(["GV", 1469, "D", 84, "G", 938], outputs[3])
      assert_equal(["GV", 1469, "D", 84, "G", 938, "P"], outputs[4])
      assert_equal(["GV", 1469, "D", 84, "G", 938], outputs[5])
    end

    it 'raises on multibyte characters' do
      subject = Book.new
      subject.lcc = "ABC💀DEF"

      e = assert_raises { subject.lcc_parts }
      assert_equal "LCC 'ABC💀DEF' contains multibyte character '💀'.", e.message
    end
  end
end
