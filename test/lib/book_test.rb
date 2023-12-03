require 'test_helper'

describe Book do
  describe 'callbacks' do
    describe 'before_validation' do
      it 'sets barcode from isbn if barcode is empty'
      it 'does not override a non-empty barcode'
      it 'sets lcc_sort_order'
    end

    describe 'after_commit' do
      it 'tells LccSortCalculator to perform a full update if needed'
    end
  end

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

  describe '#lcc=' do
    it 'sets lcc_parts'
  end

  describe '#lcc_parts' do
    it 'returns empty array if lcc is nil' do
      assert_equal([], Book.new.lcc_parts)
    end
  end
end
