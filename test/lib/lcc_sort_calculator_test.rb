require 'test_helper'

describe LccSortCalculator do
  it 'does the full process' do
    lccs = <<~EOF
      UG630.G927 1983
      B358.G78 1975
    EOF

    books = lccs.split("\n").map { |lcc| Book.new(lcc: lcc) }

    all_unpadded_parts = []
    books.each do |book|
      all_unpadded_parts << LccSortCalculator.lcc_parts(book.lcc)
    end

    expected = [
      ['UG', 630, 'G', 927, 1983],
      [ 'B', 358, 'G',  78, 1975]
    ]
    assert_equal(expected, all_unpadded_parts)

    padding_mask = LccSortCalculator.lcc_padding_mask(all_unpadded_parts)
    expected = [2, 3, 1, 3, 4]
    assert_equal(expected, padding_mask)

    all_padded_parts = LccSortCalculator.pad_all_parts(all_unpadded_parts, padding_mask)
    expected = [
      ['UG', '630', 'G', '927', '1983'],
      ['0B', '358', 'G', '078', '1975']
    ]
    assert_equal(expected, all_padded_parts)

    all_unpadded_ints = LccSortCalculator.integerize_parts(all_padded_parts)
    expected = [
      144279630315185578995,
        1459338840511113425
    ]
    assert_equal(expected, all_unpadded_ints)

    max_length = all_unpadded_ints.map{|u| u.to_s.size }.max
    all_padded_ints = LccSortCalculator.pad_ints(all_unpadded_ints, max_length)
    expected = [
      '144279630315185578995',
      '001459338840511113425'
    ]
    assert_equal(expected, all_padded_ints)
  end

  describe '.lcc_parts' do
    it 'splits lcc into alphabetical and numeric groups' do
      outputs = []
      outputs << LccSortCalculator.lcc_parts("BH301.M54M44 1987")

      outputs << LccSortCalculator.lcc_parts("GV1469.D84 G938")

      # sequential 'other' characters
      outputs << LccSortCalculator.lcc_parts("GV1469.D84  G938")

      # starts with non-alphanum
      outputs << LccSortCalculator.lcc_parts(" GV1469.D84 G938")

      # new group on last character
      outputs << LccSortCalculator.lcc_parts("GV1469.D84 G938P")

      # ends with non-alphanum
      outputs << LccSortCalculator.lcc_parts("GV1469.D84 G938.")

      # consecutive numeric parts
      outputs << LccSortCalculator.lcc_parts("Q124.97.F35 2020")

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
      e = assert_raises { LccSortCalculator.lcc_parts("ABC💀DEF") }
      assert_equal "LCC 'ABC💀DEF' contains multibyte character '💀'.", e.message
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

      mask = LccSortCalculator.lcc_padding_mask(parts)

      # longest 1st part is 3 chars
      # longest 2nd part is 2 chars
      # longest 3rd part is 1 char
      assert_equal([3, 2, 1], mask)
    end
  end

  describe '.pad_all_parts' do
    it 'pads each part to the length described in padding_mask' do
      mask = [3, 2, 3]
      parts = [
        ['A', 'A', 'A'],
        ['B', 'B']
      ]

      actual = LccSortCalculator.pad_all_parts(parts, mask)
      expected = [
        ['00A', '0A', '00A'],
        ['00B', '0B', '000']
      ]
      assert_equal(expected, actual)
    end
  end

  describe '.integerize_parts' do
    it 'creates an integer from each item' do
      all_padded_parts = [
        ['00A', '0A', '00A'],
        ['B0B', '0B', '000']
      ]

      all_unpadded_ints = LccSortCalculator.integerize_parts(all_padded_parts)
      expected = [
        '00A0A00A'.to_i(36),
        'B0B0B000'.to_i(36)
      ]
      assert_equal(expected, all_unpadded_ints)
    end
  end

  describe '.pad_ints' do
    it 'ensures all numeric strings are padded to the same length' do
      unpadded_ints = [
        '00A0A00A'.to_i(36),
        'B0B0B000'.to_i(36)
      ]
      expected = [
        605128330,
        862671446208
      ]
      assert_equal(expected, unpadded_ints)

      padded_ints = LccSortCalculator.pad_ints(unpadded_ints, 12)
      expected = [
        '000605128330',
        '862671446208'
      ]
      assert_equal(expected, padded_ints)
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

  #     sorted = LccSortCalculator.lcc_sort(books)

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
