require 'test_helper'

describe LccSortCalculator do
  before(:each) do
    Singleton.__init__(LccSortCalculator)
    @subject = LccSortCalculator.instance
  end

  # this is to show how all the parts fit together.
  it 'demonstrates full process' do
    lccs = <<~EOF
      UG630.G927 1983
      B358.G78 1975
    EOF

    books = lccs.split("\n").map { |lcc| Book.new(lcc: lcc) }

    all_unpadded_parts = books.map do |book|
                           @subject.lcc_parts(book.lcc)
                         end

    # split LCCs into their constituent parts
    # string parts are strings, and numeric parts are integers
    expected = [
      ['UG', 630, 'G', 927, 1983],
      [ 'B', 358, 'G',  78, 1975]
    ]
    assert_equal(expected, all_unpadded_parts)

    # the maximum character length at each position across all books
    padding_mask = @subject.lcc_padding_mask(all_unpadded_parts)
    expected = [2, 3, 1, 3, 4]
    assert_equal(expected, padding_mask)

    # pad each part based on the padding mask
    # string parts are right-padded, and numeric parts are left-padded
    all_padded_parts = all_unpadded_parts.map do |unpadded_part|
                         @subject.pad_parts(unpadded_part, padding_mask)
                       end
    expected = [
      ['UG', '630', 'G', '927', '1983'],
      ['B0', '358', 'G', '078', '1975']
    ]
    assert_equal(expected, all_padded_parts)
  end

  describe '.full_update_if_needed' do
    it 'updates all books if given book changed registry values'
    it 'returns true if a full update was performed'
    it 'returns false if a full update was not needed'
    it 'returns false if a full update is already in progress'
  end

  describe '.update_registered_padding_values' do
    it 'sets registry values based on given books'
    it 'returns true if registry was changed'

    # individual padding mask value could go up
    # overall length of padding mask could get longer
    # integer padding could go up
    it 'returns false if registry was not changed'
  end

  describe '.set_lcc_sort_orders' do
    it 'sets the lcc_sort_order for each given book'
    it 'works when given a single book'
  end

  describe '.lcc_parts' do
    it 'splits lcc into alphabetical and numeric groups' do
      outputs = []
      outputs << @subject.lcc_parts("BH301.M54M44 1987")

      outputs << @subject.lcc_parts("GV1469.D84 G938")

      # sequential 'other' characters
      outputs << @subject.lcc_parts("GV1469.D84  G938")

      # starts with non-alphanum
      outputs << @subject.lcc_parts(" GV1469.D84 G938")

      # new group on last character
      outputs << @subject.lcc_parts("GV1469.D84 G938P")

      # ends with non-alphanum
      outputs << @subject.lcc_parts("GV1469.D84 G938.")

      # consecutive numeric parts
      outputs << @subject.lcc_parts("Q124.97.F35 2020")

      # puts outputs.inspect

      assert_equal(["BH",  301, "M", 54,  "M",   44, 1987], outputs[0])
      assert_equal(["GV", 1469, "D", 84,  "G",  938      ], outputs[1])
      assert_equal(["GV", 1469, "D", 84,  "G",  938      ], outputs[2])
      assert_equal(["GV", 1469, "D", 84,  "G",  938      ], outputs[3])
      assert_equal(["GV", 1469, "D", 84,  "G",  938,  "P"], outputs[4])
      assert_equal(["GV", 1469, "D", 84,  "G",  938      ], outputs[5])
      assert_equal(["Q",   124, 97,  "F", 35,  2020      ], outputs[6])
    end

    it 'raises on multibyte characters' do
      e = assert_raises { @subject.lcc_parts("ABC💀DEF") }
      assert_equal "LCC 'ABC💀DEF' contains multibyte character '💀'.", e.message
    end

    it 'returns empty array for nil lcc' do
      assert_equal [], @subject.lcc_parts('')
      assert_equal [], @subject.lcc_parts(nil)
    end
  end

  describe '.lcc_padding_mask' do
    it 'identifies the longest sub-part of all given lcc values' do
      parts = [
        [  1           ],
        [  1,   1      ],
        [999,  'A', 'G'],
        [ 'B', 12      ]
      ]

      mask = @subject.lcc_padding_mask(parts)

      # longest 1st part is 3 chars
      # longest 2nd part is 2 chars
      # longest 3rd part is 1 char
      assert_equal([3, 2, 1], mask)
    end
  end

  describe '.pad_parts' do
    it 'pads each part to the length described in padding_mask' do
      mask = [3, 2, 3]
      actual = @subject.pad_parts(['A', 11, 2], mask)
      assert_equal(['A00', '11', '002'], actual)
    end

    it 'returns same number of entries as in the mask, even if parts is shorter' do
      mask = [3, 2, 3]
      actual = @subject.pad_parts(['B', 'B'], mask)
      assert_equal(['B00', 'B0', '000'], actual)
    end
  end

  # describe '.lcc_sort' do
  #   it 'sorts shorter values first' do
  #     books = [
  #       book_a = Book.new(lcc: '1'),
  #       book_b = Book.new(lcc: 'PS'),
  #       book_c = Book.new(lcc: 'PS3554.E449.D4222'),
  #       book_d = Book.new(lcc: 'PS3554.O415E5 2005'),
  #       book_e = Book.new(lcc: 'TP570'),
  #       book_f = Book.new(lcc: 'TP570.1'),
  #       book_g = Book.new(lcc: 'TP570.J34 1996'),
  #     ]

  #     sorted = @subject.lcc_sort(books)

  #     assert_equal(sorted[0], book_a)
  #     assert_equal(sorted[1], book_b)
  #     assert_equal(sorted[2], book_c)
  #     assert_equal(sorted[3], book_d)
  #     assert_equal(sorted[4], book_e)
  #     assert_equal(sorted[5], book_f)
  #     assert_equal(sorted[6], book_g)
  #   end

  #   it 'sorts by title when lcc values are identical'
  # end
end
