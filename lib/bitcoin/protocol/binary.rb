# Binary mixin handles (de)serialization of:
#
#   - Integer numbers ✓
#   - Null terminated strings ✓
#   - Fixed size strings ✓
#
# It is meant to be used as a fluent interface to
# an IO entity, therefore assumes that read(n)
# and write(str) methods are available where this
# module is mixed in.
#
# In order to be plaftorm agnostic, Binary inspects
# at load time machine's capabilities and adjust its
# own operations accordingly.
#
# Binary performs operations accepted by the following
# grammar:
#
#  operation  ::= 'read' | 'write'
#
#  OP_INT ::= operation '_' integer_type bits ('_' endianness)?
#
#  integer_type  ::= 'uint' | 'int'
#  bits          ::= '8' | '16' | '32' | '64' | '128' | '256'
#  endianness    ::= 'native' | 'little' | 'big' | 'network'
#
#  OP_STR ::= operation '_' (str_padding '_')?
#             string_flavor '_' str_preposition integer '_' str_size
#
#  str_padding      ::= 'null_padded' | 'c_'
#  string_flavor    ::= 'string' | 'fixed_string' | 'binary_string'
#  str_preposition  ::= '_of_'
#  integer          ::= [0-9]+
#  str_size         ::= 'bytes'
#
module Bitcoin::Protocol
  module Binary
    OP_RE     = /(read|write)_/
    INT_RE    = /(uint|int)(8|16|32|64|128|256)_?(native|little|big|network)?/
    STR_RE    = /(null_padded|c_)?((binary_|fixed_)?string)(_of_)[0-9]+(bytes)/
    OP_INT_RE = Regexp::compile(OP_RE.source + INT_RE.source)
    OP_STR_RE = Regexp::compile(OP_RE.source + STR_RE.source)

    KNOWN_RE  = Regexp::compile(OP_INT_RE.source + OP_STR_RE.source)

    NUL = 0.chr

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

    @@pack_mappings = {
      1 => { :uint => { :native => 'C' },
             :int  => { :native => 'c' } },
      2 => { :uint => { :native => 'S', :little => 'v', :big => 'n' },
             :int  => { :native => 's', :little => 'v', :big => 'n' } },
      4 => { :uint => { :native => 'L', :little => 'V', :big => 'N' },
             :int  => { :native => 'l', :little => 'V', :big => 'N' } },
      8 => { :uint => { :native => 'Q' },
             :int  => { :native => 'q' } } }

    BIT_MASK = {  4 => 0xF, 8 => 0xFF, 16 => 0xFFFFF,
                 32 => 0xFFFFFFFF, 64 => 0xFFFFFFFFFFFFFFFF,
                128 => 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF }

    DEFAULT_BIT_MASK = module_eval { (1.size >> 1) * 8 }

    def msb(num, bits=DEFAULT_BIT_MASK) (num & BIT_MASK[bits]) end
    def lsb(num, bits=DEFAULT_BIT_MASK) ((num >> bits) & BIT_MASK[bits]) end

    def split_msb_lsb(num, bits)
      [msb(num, bits), lsb(num,bits) ]
    end

    def concat(msb, lsb, bits)
      lsb + (msb << bits)
    end

    def read_uint256_little
      lsb  = read_uint128_little
      msb  = read_uint128_little
      concat(msb, lsb, 128)
    end

    def read_uint256_big
      msb = read_uint64_big
      lsb = read_uint64_big
      concat(msb, lsb, 128)
    end
    alias :read_uint256_network :read_uint256_big

    def read_uint256_native
      little_endian_platform? ? read_uint256_little : read_uint256_big
    end
    alias :read_uint256 :read_uint256_native

    def write_uint256_little(n)
      msb, lsb = split_msb_lsb(n, 128)
      write_uint128_little(msb)
      write_uint128_little(lsb)
    end

    def write_uint256_big(n)
      lsb, msb = split_msb_lsb(n, 128)
      write_uint128_big(msb)
      write_uint128_big(lsb)
    end

    def write_uint256_native(n)
      little_endian_platform? ? write_uint256_little(n) : write_uint256_big(n)
    end
    alias :write_uint256 :write_uint256_native

    def read_uint128_little
      lsb = read_uint64_little
      msb = read_uint64_little
      concat(msb, lsb, 64)
    end

    def read_uint128_big
      msb = read_uint64_big
      lsb = read_uint64_big
      concat(msb, lsb, 64)
    end
    alias :read_uint128_network :read_uint128_big

    def read_uint128_native
      little_endian_platform? ? read_uint128_little : read_uint128_big
    end
    alias :read_uint128 :read_uint128_native

    def write_uint128_little(n)
      lsb, msb = split_msb_lsb(n, 64)
      write_uint64_little(lsb)
      write_uint64_little(msb)
    end

    def write_uint128_big(n)
      lsb, msb = split_msb_lsb(n, 64)
      write_uint64_big(msb)
      write_uint64_big(lsb)
    end

    def write_uint128_native(n)
      little_endian_platform? ? write_uint128_little(n) : write_uint128_big(n)
    end
    alias :write_uint128 :write_uint128_native

    def read_uint64_little
      lsb = readn_unpack(4, 'L', :little)
      msb = readn_unpack(4, 'L', :little)
      concat(msb, lsb, 32)
    end

    def read_uint64_big
      msb = readn_unpack(4, 'L', :big)
      lsb = readn_unpack(4, 'L', :big)
      concat(msb, lsb, 32)
    end
    alias :read_uint64_network :read_uint64_big

    def read_uint64_native
      little_endian_platform? ? read_uint64_little : read_uint64_big
    end
    alias :read_uint64 :read_uint64_native

    def write_uint64_little(n)
      lsb, msb = split_msb_lsb(n,32)
      write_pack(lsb, 'L', :little)
      write_pack(msb, 'L', :little)
    end

    def write_uint64_big(n)
      lsb, msb = split_msb_lsb(n,32)
      write_pack(msb, 'L', :big)
      write_pack(lsb, 'L', :big)
    end

    def write_uint64_native(n)
      little_endian_platform? ? write_uint64_little(n) : write_uint64_big(n)
    end
    alias :write_uint64 :write_uint64_native

    # obtains the correct pack format for the arguments
    def format(byte_size, type, byte_order)
      byte_order = :native if byte_order.nil?
      byte_order = :big if byte_order.equal?(:network)
      @@pack_mappings[byte_size][type][byte_order]
    end

    # read n bytes and unpack, swapping bytes as per endianness
    def readn_unpack(size, template, byte_order=NATIVE_BYTE_ORDER)
      str = readn(size)
      str.reverse! if not native_byte_order.equal? byte_order # spotted problem in pack
      str.unpack(template).first
    end

    # read exactly n characters from the buffer, otherwise raise an exception.
    def readn(n)
      str = read(n)
      raise "couldn't read #{n} characters." if str.nil? or str.size != n
      str
    end

    # TODO: rewrite this method w/o messing with buffer instance vars:
    # call buffer API instead and declare used methods as a dependence
    def read_fixed_size_string(size, opt = {:padding => nil})
      str = @content[@position, size]
      @position += size
      # opt[:padding] ? str.split_msb_lsb(opt[:padding]).first : str
      str
    end

    # TODO: idem as above
    def read_c_string
      nul_pos = @content.index(NUL, @position)
      raise "no C string found." unless nul_pos
      sz = nul_pos - @position
      str = @content[@position, sz]
      @position += sz + 1
      return str
    end

    def read_string(opt={:size => nil, :padding => 0.chr})
      if opt[:size]
        read_fixed_size_string(opt[:size], opt[:padding])
      else
        read_c_string
      end
    end

    # writes a number and pack it, swapping bytes as per endianness
    def write_pack(number, template, byte_order=NATIVE_BYTE_ORDER)
      str = [number].pack(template)
      str.reverse! if not native_byte_order.equal? byte_order # blame Array#pack
      write(str)
    end

    # writes the string and appends NUL
    def write_c_string(str)
      #TODO: improve input validation
      raise ArgumentError, "Invalid Ruby string" if str.include?(NUL)
      write(str)
      write(NUL)
    end

    def write_string(content, opt = {:padding  => nil, :size => nil})
      if (size = opt[:size]) && (opt[:size].kind_of? Integer)
        output_string = content[0..size]
        # output_string = output_string.ljust(size, opt[:padding]) if opt[:padding]
        write(output_string)
      else
        write_c_string(content)
      end
    end

    def write_fixed_size_string(content="")
      write_string(content, :size => content.size)
    end

    def self.recognize?(type)
      type.to_s =~ INT_RE || type.to_s =~ STR_RE
    end

    def method_missing(method_name, *args, &block)
      if method_name.to_s =~ OP_INT_RE
        op, type, bits, byte_order = Regexp.last_match[1..4]
        # string → sym
        op, type, byte_order = [op, type].map!(&:to_sym)
        # adjust bits to bytes
        byte_size = (bits.to_i / 8)
        # normalize endianness
        byte_order = byte_order.to_sym unless byte_order.nil?
        byte_order = :big if byte_order == 'network'

        fmt = format(byte_size,type,byte_order)

        case op
        when :read
          self.class.send :define_method, method_name do
            readn_unpack(byte_size, fmt, byte_order)
          end
          self.send method_name
        when :write
          if (args.first.kind_of? Integer) && (args.size == 1)
            self.class.send :define_method, method_name do |value|
              write_pack(value, fmt, byte_order)
            end
            self.send method_name, args.first
          end
        end
      elsif method_name.to_s =~ OP_STR_RE
        op, string_flavor = Regexp.last_match[1..2]
        case op
        when :read
          options = args.first.indexes(:size, :padding)
          self.send :read_string, options
        when :write
          str, options = args.shift, args
          self.send :write_string, str, options
        end
      else
        super
      end
    end

    # Tells the byte size required for the method passed as argument.
    # When recognized.
    def size_of(type, object=nil)
      case
      when type.to_s =~ INT_RE then Regexp.last_match[2].to_i / 8
      when type.to_s =~ STR_RE then Regexp.last_match[-2].to_i
      end
    end

    def recognize?(type)
      (type.to_s =~ Regexp.union(INT_RE,STR_RE)) ? true : false
    end
  end
end

