require 'base64'

class Registry < ApplicationRecord
  self.table_name = 'registry'

  # save a value in the hash
  def self.[]=(key_name, value)
    item = where(key_name: key_name)
            .lock
            .first_or_initialize

    if value.nil?
      item.destroy
    else
      item.update(
        marshalled: Base64.encode64(Marshal.dump(value))
      )
    end
  end

  # fetch a value from the hash.
  #
  # @return The requested value, or nil if the requested key does not exist.
  def self.[](key_name)
    value = nil
    item = select(:marshalled).find_by(key_name: key_name)
    if item
      value = Marshal.load(Base64.decode64(item.marshalled))
    end

    value
  end

  def self.lcc_part_padding_mask
    self['lcc_part_padding_mask'] || []
  end

  def self.lcc_part_padding_mask=(value)
    if !value.is_a?(Array)
      raise "#{value} must be an array."
    end
    self['lcc_part_padding_mask'] = value
  end

  def self.lcc_sort_order_size
    self['lcc_sort_order_size'] || 0
  end

  def self.lcc_sort_order_size=(value)
    if !value.is_a?(Integer)
      raise "#{value} must be an integer."
    end
    self['lcc_sort_order_size'] = value
  end
end
