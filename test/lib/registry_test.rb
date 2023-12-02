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
end
