require 'test_helper'

describe Registry do
  it 'can store scalars' do
    Registry['foo'] = 'bar'
    assert_equal 'bar', Registry['foo']
  end

  it 'can store complex values' do
    Registry['foo'] = { 'bar' => 'baz' }
    assert_equal({ 'bar' => 'baz' }, Registry['foo'])
  end

  it 'can store datetimes' do
    now = Time.now
    Registry['now'] = now
    assert_equal now, Registry['now']
  end

  describe '.lcc_part_padding_mask' do
    it 'returns empty array if no value is set'
    it 'returns stored value'
  end

  describe '.lcc_part_padding_mask=' do
    it 'sets given value in registry'
    it 'raises if given a non-Array'
  end

  describe '.lcc_sort_order_size' do
    it 'returns 0 if no value is set'
    it 'returns stored value'
  end

  describe '.lcc_sort_order_size=' do
    it 'sets given value in registry'
    it 'raises if given a non-Integer'
  end
end
