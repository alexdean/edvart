class LccSortCalculator
  def self.update_lcc_sorts
    books = Book.all
    all_unpadded_parts = []
    books.each do |book|
      all_unpadded_parts << lcc_parts(book.lcc)
    end

    padding_mask = lcc_padding_mask(all_unpadded_parts)

    # apply padding to individual parts
    all_padded_parts = all_unpadded_parts.map do |unpadded_parts|
                         pad_parts(unpadded_parts, padding_mask)
                       end

    # convert padded parts to ints
    all_unpadded_ints = all_padded_parts.map do |padded_parts|
                          integerize_parts(padded_parts)
                        end

    # the final lcc values will be stored as BLOBs
    # we need to pad shorter numeric strings to ensure all BLOBs have the same size
    # since we're using them for sorting
    max_length = all_unpadded_ints.map{|u| u.to_s.size }.max

    all_padded_ints = pad_ints(all_unpadded_ints, max_length)

    books.each_with_index do |book, idx|
      book.update!(lcc_sort: all_padded_ints[idx])
    end

    books
  end

  # split an LCC string into an array of parts
  #
  # string parts are strings, and numeric parts are integers
  #
  # @example
  #  LccSortCalculator.lcc_parts("BH301.M54M44 1987")
  #  # => ["BH", 301, "M", 54, "M", 44, 1987]
  #
  # @param lcc [String] the LCC string to split
  # @return [Array] an array of parts
  def self.lcc_parts(lcc)
    output = []

    # ascii ranges
    letters = 65..90
    numbers = 48..57

    current_group_type = nil
    current_group = ''
    lcc.to_s.chars.each_with_index do |c|
      if c.bytes.size > 1
        raise "LCC '#{lcc}' contains multibyte character '#{c}'."
      end

      normalized = c.upcase
      type = if letters.include?(normalized.bytes[0])
               :letter
             elsif numbers.include?(normalized.bytes[0])
               :number
             else
               :other
             end

      # init on first iteration only
      if current_group_type.nil?
        current_group_type = type
      end

      # this says "if the current character does not go with the current group"
      if current_group_type != type
        lcc_parts_finalize_group(current_group, current_group_type, to: output)

        current_group_type = type
        current_group = ''
      end

      current_group += normalized
    end

    # whatever's left in current_group should be flushed to output.
    lcc_parts_finalize_group(current_group, current_group_type, to: output)

    output
  end

  # identify the longest sub-part of all given lcc values
  #
  # @example
  #   parts = [
  #     [999,  'A', 'G'],
  #     [ 'B', 12]
  #   ]
  #
  #   LccSortCalculator.lcc_padding_mask(parts)
  #   # => [3, 2, 1]
  #
  # @param all_unpadded_parts [Array<Array>] an array of arrays of parts
  # @return [Array<Integer>]
  def self.lcc_padding_mask(all_unpadded_parts)
    mask = []
    all_unpadded_parts.each do |parts|
      parts.each_with_index do |part, idx|
        mask[idx] = [
                      part.to_s.size,
                      mask[idx].to_i
                    ].max
      end
    end
    mask
  end

  # pad individual parts according to the mask
  #
  # @example
  #   mask = [3, 2, 3]
  #   parts = ['A', 11, 2]
  #
  #   LccSortCalculator.apply_part_padding(parts, mask)
  #   # => ['A00', '11', '002']
  #
  # @param unpadded_parts [Array] an array of parts
  # @param padding_mask [Array<Integer>] an array of padding lengths
  # @return [Array<String>] an array of padded parts
  def self.pad_parts(unpadded_parts, padding_mask)
    idx = -1
    padding_mask.map do |padding_length|
      idx += 1
      unpadded = unpadded_parts[idx]

      if unpadded.is_a?(String)
        unpadded.ljust(padding_length, '0')
      else
        unpadded.to_s.rjust(padding_length, '0')
      end
    end
  end

  # convert padded parts into a single number
  #
  # by treating the joined parts as a base36 numeric string
  # base36 is used because all LCC values A-Z0-9 are valid base36 digits.
  #
  # @param all_padded_parts [Array<String>] an array strings
  # @return [Integer]
  def self.integerize_parts(padded_parts)

    padded_parts.join.to_i(36)
  end

  def self.pad_ints(all_unpadded_ints, length)
    all_unpadded_ints.map do |unpadded_int|
      unpadded_int.to_s.rjust(length, '0')
    end
  end

  private

  def self.lcc_parts_finalize_group(group, group_type, to:)
    output = to

    if group_type == :number
      output << group.to_i
    elsif group_type == :letter
      output << group
    end
  end

  # def self.lcc_sort(books)
  #   books.sort { |a,b| lcc_sort_items(a, b) }
  # end

  # def self.lcc_sort_items(book_a, book_b)
  #   book_a_lcc_parts = book_a.lcc_parts
  #   book_b_lcc_parts = book_b.lcc_parts

  #   book_a_lcc_parts.each_with_index do |a_part, idx|
  #     b_part = book_b_lcc_parts[idx]

  #     # compare ints as ints
  #     # compare strings as strings
  #     # comapre int vs string as strings
  #     if a_part.class != b_part.class
  #       a_part = a_part.to_s
  #       b_part = b_part.to_s
  #     end

  #     # https://ruby-doc.org/3.2.2/Enumerable.html#method-i-sort
  #     # A negative integer if a < b.
  #     # Zero if a == b.
  #     # A positive integer if a > b.
  #     if a_part == b_part
  #       next
  #     else
  #       return a_part < b_part ? -1 : 1
  #     end
  #   end

  #   book_a_title = book_a.title.to_s.strip.downcase
  #   book_b_title = book_b.title.to_s.strip.downcase
  #   if book_a_title == book_b_title
  #     0
  #   else
  #     book_a_title < book_b_title ? -1 : 1
  #   end
  # end
end
