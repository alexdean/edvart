class LccSortCalculator
  include Singleton

  def initialize
    @in_full_update = false
  end

  def full_update
    full_update_if_needed(nil, force: true)
  end

  def full_update_if_needed(book, force: false)
    if @in_full_update
      return false
    end

    full_update_needed = update_registered_padding_values(book, force: force)
    full_update_was_performed = false

    if full_update_needed
      @in_full_update = true
      all_books = Book.all
      set_lcc_sort_order(all_books)
      all_books.each(&:save!)
      @in_full_update = false
      full_update_was_performed = true
    end

    full_update_was_performed
  end

  # update padding values in registry if needed
  #
  # return true if any registry values were changed
  # which means all lcc_sort_order values need to be re-calculated
  def update_registered_padding_values(books, force: false)
    full_update_needed = force

    # if registry is missing data (first run or corruption) or forcing full update, we need to check all books.
    if Registry.lcc_part_padding_mask == [] || Registry.lcc_sort_order_size == 0 || force
      books = Book.all
    end

    all_unpadded_parts = []
    Array(books).each do |book|
      all_unpadded_parts << book.lcc_parts
    end

    padding_mask = lcc_padding_mask(all_unpadded_parts)

    registered = Registry.lcc_part_padding_mask

    # new padding_mask is longer than registered, or has a larger value at any position
    needs_update = if padding_mask.size > registered.size
                     true
                   else
                     idx = -1
                     padding_mask.any? { |p| idx += 1; r = registered[idx].to_i; p > r }
                   end
    if needs_update
      Registry.lcc_part_padding_mask = padding_mask
      full_update_needed = true
    end

    full_update_needed
  end

  def set_lcc_sort_order(books)
    part_padding_mask = Registry.lcc_part_padding_mask
    lcc_sort_order_size = Registry.lcc_sort_order_size

    Array(books).each_with_index do |book, idx|
      padded_parts = pad_parts(book.lcc_parts, part_padding_mask)
      book.lcc_sort_order = padded_parts.join
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
  def lcc_parts(lcc)
    output = []

    current_group_type = nil
    current_group = ''
    lcc.to_s.chars.each_with_index do |c|
      if AsciiUtil.multibyte?(c)
        raise "LCC '#{lcc}' contains multibyte character '#{c}'."
      end

      normalized = c.upcase
      type = AsciiUtil.classify(normalized.bytes[0])

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
  def lcc_padding_mask(all_unpadded_parts)
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
  def pad_parts(unpadded_parts, padding_mask)
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

  private

  def lcc_parts_finalize_group(group, group_type, to:)
    output = to

    if group_type == :number
      output << group.to_i
    elsif group_type == :letter
      output << group
    end
  end

  # def lcc_sort(books)
  #   books.sort { |a,b| lcc_sort_items(a, b) }
  # end

  # def lcc_sort_items(book_a, book_b)
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
