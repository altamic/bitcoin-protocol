module Bitcoin::Protocol
  module Binary

    # Returns the number of bytes used to encode an integer number
    INTEGER_SIZE_IN_BYTES = module_eval { 1.size }
    def integer_size_in_bytes() INTEGER_SIZE_IN_BYTES end
    alias :word_size_in_bytes :integer_size_in_bytes

    def little_endian_byte_order() :little end
    def big_endian_byte_order()    :big end
    alias :network_byte_order :big_endian_byte_order

    # A machine architecture is said to be little endian if puts first the
    # LSB. We evaluate the first byte of the number 1 packed as an integer.
    # While first_byte is a Fixnum in Ruby 1.8.x, it is a string in 1.9.x;
    # in latter case we employ the ord method to obtain the ordinal number
    # associated,if is the case. Underlying machine is l.e. if the LSB is 1.

    NATIVE_BYTE_ORDER = module_eval do
      first_byte = [1].pack('i')[0]
      first_byte = first_byte.ord if RUBY_VERSION =~ /^1\.9/
      first_byte == 1 ? :little : :big
    end

    def native_byte_order() NATIVE_BYTE_ORDER end

    def little_endian_platform?() native_byte_order.equal? :little end
    def big_endian_platform?()    native_byte_order.equal? :big end
    alias :network_endian_platform? :big_endian_platform?

    # uint16_network
    def read_uint16_network
      readn_unpack(2, 'n', :big)
    end

    def write_uint16_network(number)
      pack_write(number, 'S', :big)
    end

    # uint32_little
    def read_uint32_little
      readn_unpack(4, 'V')
    end

    def write_uint32_little(number)
      pack_write(number, 'V', :little)
    end

    # int32_little
    def read_int32_little

    end

    def write_int32_little

    end

    # uint64_little
    def read_uint64_little

    end

    def write_uint64_little

    end

    # int64_little
    def read_int64_little

    end

    def write_int64_little

    end

    # uint128_network
    def read_uint128_network

    end

    def write_uint128_network

    end
    
    # uint256_little
    def read_uint256_little

    end

    def write_uint256_little

    end

    # read exactly n characters from the buffer, otherwise raise an exception.
    def readn(n)
      buf = read(n)
      raise EOFError if buf == nil
      return buf if buf.size == n

      n -= buf.size

      while n > 0
        str = read(n)
        raise EOFError if str == nil
        buf << str
        n -= str.size
      end
      return buf
    end

    # read n bytes and unpack, swapping as per endianness
    def readn_unpack(size, template, byte_order=NATIVE_BYTE_ORDER)
      str = readn(size)
      str.reverse! if byte_order.equal? byte_order # spotted problem in pack
      str.unpack(template).first
    end

    # writes a number and pack it, swapping bytes as per endianness
    def pack_write(number, template, endianness)
      str = [number].pack(template)
      str.reverse! if not endianness.equal? NATIVE_BYTE_ORDER
      write(str)
    end

    def read_null_padded_string(size)
      str = readn(size)
      str.split(/\000/).first or str
    end
  end
end

