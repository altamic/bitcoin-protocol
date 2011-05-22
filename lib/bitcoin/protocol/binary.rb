module Bitcoin::Protocol
  module Binary
    # Returns the integer of bytes used to encode an integer integer
    INTEGER_SIZE_IN_BYTES = module_eval { 1.size }
    def integer_size_in_bytes() INTEGER_SIZE_IN_BYTES end
    alias :word_size_in_bytes :integer_size_in_bytes

    def little_endian_byte_order() :little end
    def big_endian_byte_order()    :big end
    alias :network_byte_order :big_endian_byte_order

    # A machine architecture is said to be little endian if puts first the
    # LSB. We evaluate the first byte of the integer 1 packed as an integer.
    # first_byte is a Fixnum in Ruby 1.8.x, while it is a string in 1.9.x;
    # in latter case we employ the ord method to obtain the ordinal integer
    # associated, underlying machine is l.e. if the LSB is 1.

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

    def write_uint16_network(integer)
      str = [integer].pack('S')
      str.reverse! if little_endian_platform?
      write(str)
    end

    # uint32_little
    # V
    # 32-bit unsigned integer
    # unsigned long
    # Little endian
    def read_uint32_little
      readn_reverse_unpack(4, 'V')
    end

    #
    def write_uint32_little(integer)
      str = [integer].pack('N')
      str.reverse! if network_endian_platform?
      write(str)
    end

    # int32_little
    def read_int32_little
      if little_endian_platform?
        readn_unpack(4, 'l')
      else
        readn_reverse_unpack(4,'l')
      end
    end

    def write_int32_little(integer)
      pack_write(integer, 'l')
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

    def write_uint64_little(integer)
      if little_endian_platform?
        pack_write(integer, 'Q')
      else
        pack_reverse_write(integer, 'Q')
      end
    end

    # int64_little
    def read_int64_little
      if little_endian_platform?
        readn_unpack(8, 'q')
      else
        readn_reverse_unpack(8, 'q')
      end
    end

    def write_int64_little(integer)
      if little_endian_platform?
        pack_write(integer, 'q')
      else
        pack_reverse_write(integer, 'q')
      end
    end

    # uint128_network
    def read_uint128_network
       msb = read_uint64
       lsb = read_uint64
       return ((msb >> 64) + lsb)
    end

    def write_uint128_network(integer)
      # write_uint64_()
    end
    
    # uint256_little
    def read_uint256_little

    end

    def write_uint256_little(integer)

    end

    # read exactly n characters from the buffer, otherwise raise an exception.
    def readn(n)
      if respond_to? :read_nonblock
        read_nonblock(n, '')
      else
        read(n,'')
      end
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

    # writes a integer and pack it
    def pack_write(integer, template)
      write([integer].pack(template))
    end

    def pack_reverse_write(integer, template)
      str = [integer].pack(template)
      str.reverse!
      write(str)
    end
  end
end

