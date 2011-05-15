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
      readn_unpack(2, 'n')
    end

    def write_uint16_network(number)
      str = [val].pack('S')
      str.reverse! if little_endian_platform?
      write(str)
    end

    # uint32_little
    def read_uint32_little
      readn_reverse_unpack(4, 'V')
    end

    #
    def write_uint32_little(number)
      str = [number].pack('N')
      str.reverse! if network_endian_platform?
      write(str)
    end

    # int32_little
    def read_int32_little
      ru_swap(4, 'l', :big)
    end

    def write_int32_little(number)
      pack_write(number, 'V')
    end

    # 64-bit unsigned integer
    # unpack format: Q
    # c-type: uint64_t
    # Byte order: Native
    def read_uint64_little
      if little_endian_platform?
        readn_unpack(8, 'Q')
      else
        readn_reverse_unpack(8, 'Q')
      end
    end

    def write_uint64_little(number)
      if little_endian_platform?
        pack_write(number, 'Q')
      else
        pack_reverse_write(number, 'Q')
      end
    end

    # int64_little
    def read_int64_little

    end

    def write_int64_little(number)

    end

    # uint128_network
    def read_uint128_network

    end

    def write_uint128_network(number)

    end
    
    # uint256_little
    def read_uint256_little

    end

    def write_uint256_little(number)

    end

    # read exactly n characters from the buffer, otherwise raise an exception.
    def readn(n)
      read_nonblock(n, '')
    end

    private
    def readn_unpack(size, template)
      readn(size).unpack(template).first
    end

    def readn_reverse_unpack(size, template)
      str = readn(size)
      str.reverse!
      str.unpack(template).first
    end

    # writes a number and pack it
    def pack_write(number, template)
      write([number].pack(template))
    end

    def pack_reverse_write(number, template)
      str = [number].pack(template)
      str.reverse!
      write(str)
    end
  end
end

