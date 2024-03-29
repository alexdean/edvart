class AsciiUtil
  # ascii ranges
  @letters = (65..90).freeze
  @numbers = (48..57).freeze

  def self.classify(byte)
    if @letters.include?(byte)
      :letter
    elsif @numbers.include?(byte)
      :number
    else
      :other
    end
  end

  def self.multibyte?(string)
    string.bytes.size > 1
  end
end
