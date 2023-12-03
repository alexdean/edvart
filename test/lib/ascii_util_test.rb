require 'test_helper'

describe AsciiUtil do
  describe '.valid_base36?' do
    it 'is true for an empty string'
    it 'is true for strings which contain only ascii alphanumerics'
    it 'is false for strings containing non-ascii-alnum characters'
    it 'is false for non-String arguments'
  end
end
