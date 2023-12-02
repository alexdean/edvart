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
        # formatted = PersistentHash::Formatter.format(value)
        item.update(
          # readable_value: formatted,
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
end
